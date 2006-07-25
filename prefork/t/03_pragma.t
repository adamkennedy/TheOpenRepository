#!/usr/bin/perl -w

# Load testing for prefork.pm

use strict;
use lib ();
use UNIVERSAL 'isa';
BEGIN {
	$| = 1;
	unless ( $ENV{HARNESS_ACTIVE} ) {
		require FindBin;
		chdir ($FindBin::Bin = $FindBin::Bin); # Avoid a warning
		lib->import(
			File::Spec->catdir(
				File::Spec->updir(),
				File::Spec->updir(),
				'modules')
			);
	}
}

use Test::More tests => 12;

# Try to prefork-load a module
use_ok( 'prefork', 'File::Spec::Functions' );
is( $prefork::MODULES{'File::Spec::Functions'}, 'File/Spec/Functions.pm', 'Module is added to queue' );
ok( ! $INC{'File/Spec/Functions.pm'}, 'Module is not loaded' );

# Load outstanding modules
is( $prefork::FORKING, '', 'The $FORKING variable is false' );
use_ok( 'prefork', ':enable' );
is( scalar(keys %prefork::MODULES), 0, 'All modules are loaded by enable' );
is( $prefork::FORKING, 1, 'The $FORKING variable is set' );
ok( $INC{'File/Spec/Functions.pm'}, 'Module is now loaded' );

# use in pragma form after enabling
ok( ! $INC{'Test/Simple.pm'}, 'Test::Simple is not loaded' );
use_ok( 'prefork', 'Test::Simple' );
is( scalar(keys %prefork::MODULES), 0, 'The %MODULES hash is still empty' );
ok( $INC{'Test/Simple.pm'}, 'Test::Simple is loaded' );

exit(0);
