#!/usr/bin/perl

# Constructor/connection testing for JSAN::Transport

use strict;
BEGIN {
    $|  = 1;
    $^W = 1;
}

use Test::More tests => 22;
use File::Remove    ();
use LWP::Online     ();
use JSAN::Transport ();

my $yamlindex = 'index.yaml';

BEGIN { File::Remove::remove( \1, 'temp' ) if -e 'temp'; }
END   { File::Remove::remove( \1, 'temp' ) if -e 'temp'; }






#####################################################################
# Tests

#####################################################################
# Sanity

ok( JSAN::Transport->init( mirror_local => 'temp' ), '->init returns true' );
isa_ok( JSAN::Transport->_self,        'JSAN::Transport' );
isa_ok( JSAN::Transport->_self->_self, 'JSAN::Transport' );
isa_ok( JSAN::Transport->mirror_location, 'URI::ToDisk' );
ok( JSAN::Transport->mirror_remote, '->mirror_remote returns true'  );
ok( JSAN::Transport->mirror_local, '->mirror_local returns true' );
is( JSAN::Transport->verbose, '', '->verbose is false by default' );





#####################################################################
# Online tests

# Are we online
my $online = LWP::Online::online();

SKIP: {
    skip( "Skipping online tests", 15 ) unless $online;

    # Pull the index as a test
    my $location = JSAN::Transport->file_location($yamlindex);
    isa_ok( $location, 'URI::ToDisk' );


    my $qm_sqlindex = quotemeta $yamlindex;
    ok( $location->uri =~ /$qm_sqlindex$/, '->file_location actually appends filename' );


    my $rv = JSAN::Transport->file_get($yamlindex);

    isa_ok( $rv, 'URI::ToDisk' );
    is_deeply( $location, $rv, '->file_get returns URI::ToDisk as expected' );

    ok( -f $rv->path, '->file_get actually gets the file to the expected location' );
    is( JSAN::Transport->file_get('nosuchfile'), '', "->file_get(nosuchfile) returns ''" );


    # Pull again via mirror
    $rv = JSAN::Transport->file_mirror($yamlindex);

    isa_ok( $rv, 'URI::ToDisk' );
    is_deeply( $location, $rv, '->file_mirror returns URI::ToDisk as expected' );

    ok( -f $rv->path, '->file_mirror actually gets the file to the expected location' );
    is( JSAN::Transport->file_get('nosuchfile'), '', "->file_mirror(nosuchfile) returns ''" );

    # Check the index methods
    ok( JSAN::Transport->index_file,      '->index_file returns true' );
    ok( -f JSAN::Transport->index_file,   '->index_file exists'       );
    ok( JSAN::Transport->index_dsn,       '->index_dsn returns true'  );

    # Check the db methods
    my $dbh = JSAN::Transport->index_dbh;
    ok( $dbh, '->index_dbh returns true'  );
    isa_ok( $dbh, 'DBI::db' );
}
