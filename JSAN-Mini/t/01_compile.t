#!/usr/bin/perl -w

# Compile testing for minijsan

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

# Check their perl version
ok( $] >= 5.005, "Your perl is new enough" );

# Does the module load
require_ok('JSAN::Mini'   );

# Does the csync script compile
my $script = $ENV{HARNESS_ACTIVE}
	? catfile( 'bin', 'minijsan' )
	: catfile( updir(), 'bin', 'minijsan' );
ok( -f $script, "Found script minijsan where expected at $script" );
SKIP: {
	skip "Can't find minijsan to compile test it", 1 unless -f $script;
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
