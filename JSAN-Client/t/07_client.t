#!/usr/bin/perl

# Top level testing for JSAN::Client itself

use strict;
use File::Spec::Functions ':ALL';
BEGIN {
    $|  = 1;
    $^W = 1;
}

use Test::More tests => 17;

use Scalar::Util ();
use File::Remove ();
use JSAN::Client;
use LWP::Online 'online';

# Cache directory clean up
END {
    eval {
        my $dir = JSAN::Transport->mirror_local;
        if ( defined $dir and $dir and -e $dir ) {
            remove( \1, $dir );
        }
    };
}

# Create and/or clear the test directory
my $testdir = catdir( curdir(), '07_client' );
File::Remove::remove \1, $testdir if -e $testdir;
ok( ! -e $testdir, "Test directory '$testdir' does not exist" );
ok( mkdir($testdir), "Create test directory '$testdir'" );
END {
    File::Remove::remove \1, $testdir if -e $testdir;
}

my @requires = map { catfile(@$_) } (
    [ 'Display.js'           ],
    [ 'Display',   'Swap.js' ],
    [ 'JSAN.js'              ],
    );

ok( defined &Scalar::Util::blessed, 'Scalar::Util has blessed function' );





#####################################################################
# Test constructor and accessors

my $Client = JSAN::Client->new(
    prefix  => $testdir,
    verbose => 0,
    );
isa_ok( $Client, 'JSAN::Client' );
is( $Client->prefix, $testdir, '->prefix returns the expected path'  );
is( $Client->verbose, '',      '->verbose returns false as expected' );




#####################################################################
# Bad Params to JSAN::Client

eval {
    JSAN::Client->new( 'lib' );
};
like( $@, qr/Odd number of params/, '->new with one param dies correctly' );





#####################################################################
# Install a known library

SKIP: {
    skip( "Skipping online tests", 10 ) unless online();

    is( $Client->install_library('Display.Swap'), 1,
        '->install_library for known-good library returns true' );
    foreach my $file ( @requires ) {
        my $path = catfile( $testdir, $file );
        ok( -f $path, "Library file '$file' was installed where expected" );
    }





    ######################################################################
    # Install a known library

    # Reset test dir
    File::Remove::remove \1, $testdir if -e $testdir;
    ok( ! -e $testdir, "Test directory '$testdir' does not exist" );
    ok( mkdir($testdir), "Create test directory '$testdir'" );

    # Install matching distribution
    is( $Client->install_distribution('Display.Swap'), 1,
        '->install_disribution for known-good distribution returns true' );
    foreach my $file ( @requires ) {
        my $path = catfile( $testdir, $file );
        ok( -f $path, "Library file '$file' was installed where expected" );
    }
}

exit(0);
