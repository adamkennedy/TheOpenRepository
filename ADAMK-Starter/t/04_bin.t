#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 8;
use Test::File::Cleaner   ();
use File::Spec::Functions ':ALL';
use ADAMK::Starter        ();

# Check and clean the test directory
my $trunk   = File::Spec->catdir( 't', 'data' );
ok( -d $trunk, 'Output directory exists' );
my $cleaner = Test::File::Cleaner->new( $trunk );





#####################################################################
# Main Tests

SCOPE: {
	my $bin = catfile( 'bin', 'adamk-starter' );
	ok( -f $bin, 'Found binary' );
	my $rv = system( "$bin --module Foo::Bar --trunk $trunk" );
	is( $rv, 0, 'Binary returns 0' );
	ok( -f $starter->makefile_pl, 'Created Makefile.PL'  );
	ok( -f $starter->changes,     'Created Changes'      );
	ok( -f $starter->compile_t,   'Created 01_compile.t' );
	ok( -f $starter->main_t,      'Created 02_main.t'    );
	ok( -f $starter->module_pm,   'Created main module'  );
}
