#!/usr/bin/perl

# Main testing

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
	my $starter = ADAMK::Starter->new(
		module => 'Foo::Bar',
		trunk  => $trunk,
	);
	isa_ok( $starter, 'ADAMK::Starter' );
	ok( $starter->run, '->run ok' );
	ok( -f $starter->makefile_pl, 'Created Makefile.PL'  );
	ok( -f $starter->changes,     'Created Changes'      );
	ok( -f $starter->compile_t,   'Created 01_compile.t' );
	ok( -f $starter->main_t,      'Created 02_main.t'    );
	ok( -f $starter->module_pm,   'Created main module'  );
}
