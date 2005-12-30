#!/usr/bin/perl -w

# Compile-testing for PITA

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
			catdir('blib', 'arch'),
			'lib',
			);
	}
}

use Test::More tests => 4;

use_ok( 'PITA' );





#####################################################################
# Create a request server

my $server = PITA::Host::ResultServer->new(
	LocalAddr => '127.0.0.1',
	LocalPort => '5678',
	);
isa_ok( $server, 'PITA::Host::ResultServer' );
is( $server->LocalAddr, '127.0.0.1', 'Got back expected LocalAddr' );
is( $server->LocalPort, '5678',      'Got back expected LocalPort' );

exit(0);
