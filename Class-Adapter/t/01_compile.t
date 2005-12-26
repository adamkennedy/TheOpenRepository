#!/usr/bin/perl -w

# Compile testing for Class::Adapter

use strict;
use lib ();
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	unless ( $ENV{HARNESS_ACTIVE} ) {
		require FindBin;
		chdir ($FindBin::Bin = $FindBin::Bin); # Avoid a warning
		lib->import( catdir(updir(), 'lib') );
	}
}

use Test::More tests => 6;

# Check their perl version
ok( $] >= 5.005, "Your perl is new enough" );

# Sometimes it's hard to know when different Scalar::Util tools turned up.
# So confirm the existance of blessed
use_ok( 'Scalar::Util' );
ok( defined(&Scalar::Util::blessed), 'blessed exists in Scalar::Util' );

# Does the module load
use_ok('Class::Adapter'          );
use_ok('Class::Adapter::Builder' );
use_ok('Class::Adapter::Clear'   );

exit(0);
