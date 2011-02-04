#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 2;

# BEGIN {
	# if ( $^O ne 'MSWin32' ) {
		# plan skip_all => 'Not on Win32';
	# }
# }

use_ok( 'Perl::Dist::WiX' );
use_ok( 'Perl::Dist::VanillaWiX' );

# diag( "Testing Perl::Dist::WiX $Perl::Dist::WiX::VERSION" );
