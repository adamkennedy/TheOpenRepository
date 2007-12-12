#!/usr/bin/perl -w

# Compile testing for VCS::CSync

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

use Test::More tests => 4;

# Check their perl version
ok( $] >= 5.005, "Your perl is new enough" );

# Does the module load
use_ok('VCS::CSync');

# Does the csync script compile
my $script = $ENV{HARNESS_ACTIVE}
	? catfile( 'bin', 'csync' )
	: catfile( updir(), updir(), 'bin', 'VCS-CSync', 'csync' );
ok( -f $script, "Found script csync where expected at $script" );
SKIP: {
	skip "Can't find csync to compile test it", 1 unless -f $script;
	my $include = '';
	unless ( $ENV{HARNESS_ACTIVE} ) {
		$include = '-I' . catdir( updir(), updir(), 'modules');
	}
	my $cmd = "perl $include -c $script 1>/dev/null 2>/dev/null";
	# diag( $cmd );
	my $rv = system( $cmd );
	is( $rv, 0, "Script $script compiles cleanly" );
}

exit(0);
