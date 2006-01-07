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

use lib catdir('t', 'lib');
use Test::More tests => 15;

BEGIN {
	ok( $] > 5.005, 'Perl version is 5.005 or newer' );
	use_ok( 'Process'                 );
	use_ok( 'Process::Infinite'       );
	use_ok( 'Process::Launcher'       );
	use_ok( 'Process::Storable'       );
	use_ok( 'Process::Backgroundable' );
}

is( $Process::VERSION, $Process::Infinite::VERSION, '::Process == ::Infinite' );
is( $Process::VERSION, $Process::Storable::VERSION, '::Process == ::Storable' );
is( $Process::VERSION, $Process::Launcher::VERSION, '::Process == ::Launcher' );
is( $Process::VERSION, $Process::Backgroundable::VERSION, '::Process == ::Backgroundable' );

# Does the launcher export the appropriate things
ok( defined(&run),      'Process::Launcher exports &run'      );
ok( defined(&run3),     'Process::Launcher exports &run3'     );
ok( defined(&storable), 'Process::Launcher exports &storable' );

# Include the testing modules
use_ok( 'MySimpleProcess' );
use_ok( 'MyBackgroundProcess' );

exit(0);
