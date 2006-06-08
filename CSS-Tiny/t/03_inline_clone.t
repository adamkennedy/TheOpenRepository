#!/usr/bin/perl -w

# Formal testing for CSS::Tiny

use strict;
use lib ();
use UNIVERSAL 'isa';
use File::Spec ();
BEGIN {
	$| = 1;
	unless ( $ENV{HARNESS_ACTIVE} ) {
		require FindBin;
		chdir ($FindBin::Bin = $FindBin::Bin); # Avoid a warning
		lib->import( File::Spec->catdir(
			File::Spec->updir,
			File::Spec->updir,
			'modules',
			) );
	}
}

use Test::More tests => 13;

my $new_called = 0;

# This won't work if a testing module uses Clone
SKIP: {
	skip( "Clone unexpectedly already in use", 13 ) if $INC{'Clone.pm'};

	# Create the broken fake Clone
	$INC{'Clone.pm'} = "FAKED";
	$Clone::VERSION = '10';
	*Clone::import = sub {
		die "Clone is busted";
	};

	# Get rid of some spurious warnings
	*main::foo = *Clone::import;

	# Loads ok when Clone busted?
	use_ok('CSS::Tiny');

	# Replace the new sub with one that signals it was called
	sub mynew {
		$new_called = 1;
		return bless {}, shift;
	}
	*CSS::Tiny::new = *mynew;
	*main::foo = *CSS::Tiny::new;

	# Retry some tests to make sure the fake new works the same
	# Test trivial creation
	my $Trivial = CSS::Tiny->new();
	ok( $Trivial, '->new returns true' );
	ok( ref $Trivial, '->new returns a reference' );
	ok( isa( $Trivial, 'HASH' ), '->new returns a hash reference' );
	ok( isa( $Trivial, 'CSS::Tiny' ), '->new returns a CSS::Tiny object' );
	ok( scalar keys %$Trivial == 0, '->new returns an empty object' );

	# Try to read in a config
	my $Config = CSS::Tiny->read( 'test.css' );
	ok( $Config, '->read returns true' );
	ok( ref $Config, '->read returns a reference' );
	ok( isa( $Config, 'HASH' ), '->read returns a hash reference' );
	ok( isa( $Config, 'CSS::Tiny' ), '->read returns a CSS::Tiny object' );

	# Repeat the clone tests from 02_main.t
	$new_called = 0;
	my $copy = $Config->clone;
	isa_ok( $copy, 'CSS::Tiny' );
	is_deeply( $copy, $Config, '->clone works as expected' );
	is( $new_called, 1, 'The inline ->clone was used as expected' );
}

1;
