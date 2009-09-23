#!/usr/bin/perl

# Top level testing for JSAN::Client itself

use strict;
BEGIN {
    $|  = 1;
    $^W = 1;
}

use JSAN::URI ();
use Test::More tests => 4;
use LWP::Online 'online';





#####################################################################
# Create an object for a mirror

my $mirror = JSAN::URI->new( 'http://master.openjsan.org/' );
isa_ok( $mirror, 'JSAN::URI' );

SKIP: {
    skip( "Skipping online tests", 3 ) unless online();

    my $config = $mirror->_config;
    my $master = $mirror->_master;
    isa_ok( $config, 'Config::Tiny' );
    isa_ok( $master, 'Config::Tiny' );

    ok( $mirror->valid, "Mirror $mirror is valid" );

}

exit(0);
