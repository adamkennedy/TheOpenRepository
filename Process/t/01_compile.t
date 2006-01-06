#!/usr/bin/perl -w

# Compile-testing for Process

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
			catdir('blib', 'lib'),
			'lib',
			);
	}
}

use Test::More tests => 7;

ok( $] > 5.005, 'Perl version is 5.005 or newer' );

use_ok( 'Process'           );
use_ok( 'Process::Storable' );
use_ok( 'Process::Launcher' );

# Does the launcher export the appropriate things
ok( defined(&run),      'Process::Launcher exports &run'      );
ok( defined(&run3),     'Process::Launcher exports &run3'     );
ok( defined(&storable), 'Process::Launcher exports &storable' );

exit(0);
