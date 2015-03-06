#!perl

use DBIx::Class::Fixtures;
use Test::More tests => 4;
use lib qw(t/lib);
use DBICTest;
use Path::Class;
use Data::Dumper;
use IO::All;

use if $^O eq 'MSWin32','Devel::Confess';
# set up and populate schema
ok(my $schema = DBICTest->init_schema(), 'got schema');

my $config_dir = io->catfile(qw't var configs')->name;

# Add washedup

ok my $artist = $schema->resultset("Artist")->find(1);
ok my $washed_up = $artist->create_related('washed_up', +{});
ok $washed_up->fk_artistid;

__END__

{
    # do dump
    ok(my $fixtures = DBIx::Class::Fixtures->new({ config_dir => $config_dir, debug => 0 }), 'object created with correct config dir');
    ok($fixtures->dump({ config => 'simple.json', schema => $schema, directory => io->catfile(qw't var fixtures')->name }), 'simple dump executed okay');

    # check dump is okay
    my $dir = dir(io->catfile(qw't var fixtures artist')->name);
    ok(-e io->catfile(qw't var fixtures artist')->name, 'artist directory created');

    my @children = $dir->children;
    is(scalar(@children), 1, 'right number of fixtures created');

    my $fix_file = $children[0];
    my $HASH1; eval($fix_file->slurp());
    is(ref $HASH1, 'HASH', 'fixture evals into hash');

    is_deeply([sort $schema->source('Artist')->columns], [sort keys %{$HASH1}], 'fixture has correct keys');

    my $artist = $schema->resultset('Artist')->find($HASH1->{artistid});
    is_deeply({$artist->get_columns}, $HASH1, 'dumped fixture is equivalent to artist row');

    $schema->resultset('Artist')->delete; # so we can create the row again on the next line
    ok($schema->resultset('Artist')->create($HASH1), 'new dbic row created from fixture');
}

{
    # do dump with hashref config
    ok(my $fixtures = DBIx::Class::Fixtures->new({ config_dir => $config_dir, debug => 0 }), 'object created with correct config dir');
    ok($fixtures->dump({
        config => {
            "might_have" => {
                "fetch" => 0
            },
            "has_many" => {
                "fetch" => 0
            },
            "sets" => [{
                "class" => "Artist",
                "quantity" => 1
            }]
        },
        schema => $schema, 
        directory => io->catfile(qw't var fixtures')->name,
    }), 'simple dump executed okay');

    # check dump is okay
    my $dir = dir(io->catfile(qw't var fixtures artist')->name);
    ok(-e io->catfile(qw't var fixtures artist')->name, 'artist directory created');

    my @children = $dir->children;
    is(scalar(@children), 1, 'right number of fixtures created');

    my $fix_file = $children[0];
    my $HASH1; eval($fix_file->slurp());
    is(ref $HASH1, 'HASH', 'fixture evals into hash');

    is_deeply([sort $schema->source('Artist')->columns], [sort keys %{$HASH1}], 'fixture has correct keys');

    my $artist = $schema->resultset('Artist')->find($HASH1->{artistid});
    is_deeply({$artist->get_columns}, $HASH1, 'dumped fixture is equivalent to artist row');

    $schema->resultset('Artist')->delete; # so we can create the row again on the next line
    ok($schema->resultset('Artist')->create($HASH1), 'new dbic row created from fixture');
}