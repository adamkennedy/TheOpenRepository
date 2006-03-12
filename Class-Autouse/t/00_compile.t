#!/usr/bin/perl -w

# Load testing for Class::Autouse

use strict;
use lib ();
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	unless ( $ENV{HARNESS_ACTIVE} ) {
		require FindBin;
		$FindBin::Bin = $FindBin::Bin; # Avoid a warning
		chdir catdir( $FindBin::Bin, updir() );
		lib->import(
			catdir('blib', 'arch'),
			catdir('blib', 'lib' ),
			catdir('lib'),
			);
	}
}

use Test::More tests => 4;

# Check their perl version
ok( $] >= 5.005, "Your perl is new enough" );

# Does the module load
use_ok('Class::Autouse'        );
use_ok('Class::Autouse::Parent');

is( $Class::Autouse::VERSION, $Class::Autouse::Parent::VERSION,
	'C:A and C:A:Parent versions match' );

exit(0);
