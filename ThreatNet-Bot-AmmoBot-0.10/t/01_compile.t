#!/usr/bin/perl -w

# Load test the ThreatNet::Bot::AmmoBot module

use strict;
use lib ();
use UNIVERSAL 'isa';
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	unless ( $ENV{HARNESS_ACTIVE} ) {
		require FindBin;
		chdir ($FindBin::Bin = $FindBin::Bin); # Avoid a warning
		lib->import( catdir( updir(), updir(), 'modules') );
	}
}

# Does a script compile
sub compile_ok {
	my $dist = shift;
	my $script = shift;

	# Find the script
	my $path = $ENV{HARNESS_ACTIVE}
		? catfile( 'bin', $script )
		: catfile( updir(), updir(), 'bin', $dist, $script );
	ok( -f $path, "Found script $script where expected at $path" );
	SKIP: {
		skip( "Can't find ammobot to compile test it", 2 ) unless -f $path;
		ok( -r $path, "Have read permissions for $script" );
		my $include = join ' ', map { "-I$_" } @INC;
		my $cmd = "$^X $include -c $path 1>/dev/null 2>/dev/null";
		my $rv = system( $cmd );
		if ( $rv == -1 ) {
			diag("Failed to execute: $!");
		}
		is( $rv, 0, "Script $script compiles cleanly" );
	}
}





# Does everything load?
use Test::More 'tests' => 5;

ok( $] >= 5.005, 'Your perl is new enough' );
use_ok( 'ThreatNet::Bot::AmmoBot' );
compile_ok( 'ThreatNet-Bot-AmmoBot', 'ammobot' );

1;
