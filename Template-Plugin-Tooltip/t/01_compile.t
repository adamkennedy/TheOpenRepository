#!/usr/bin/perl -w

# Load testing for Template::Plugin::Tooltip

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

use Test::More tests => 4;

# Does everything load?
ok( $] >= 5.005, 'Your perl is new enough' );
use_ok( 'Template::Plugin::Tooltip' );

# Is Scalar::Util loaded and do we have the blessed function
ok( $Scalar::Util::VERSION, 'Scalar::Util loaded ok' );
ok( defined &Scalar::Util::blessed, 'Scalar::Util has the "blessed" function' );

1;
