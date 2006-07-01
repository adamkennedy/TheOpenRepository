#!/usr/bin/perl -w

# Compile testing for jsan2

use strict;
use lib ();
use UNIVERSAL 'isa';
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	unless ( $ENV{HARNESS_ACTIVE} ) {
		require FindBin;
		chdir ($FindBin::Bin = $FindBin::Bin); # Avoid a warning
		lib->import( catdir( updir(), 'lib') );
	}
}

use Test::More tests => 4;

# Check their perl version
ok( $] >= 5.005, "Your perl is new enough" );

# Does the module load
require_ok('JSAN::Shell2');

# Does the jsan2 script compile
my $script = $ENV{HARNESS_ACTIVE}
	? catfile( 'bin', 'jsan2' )
	: catfile( updir(), 'bin', 'jsan2' );
ok( -f $script, "Found script jsan2 where expected at $script" );
SKIP: {
	skip "Can't find jsan2 to compile test it", 1 unless -f $script;
	my $include = '';
	unless ( $ENV{HARNESS_ACTIVE} ) {
		$include = '-I' . catdir( updir(), 'lib');
	}
	my $cmd = "perl $include -c $script 1>/dev/null 2>/dev/null";
	# diag( $cmd );
	my $rv = system( $cmd );
	is( $rv, 0, "Script $script compiles cleanly" );
}

exit(0);
