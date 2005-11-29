#!/usr/bin/perl -w

# Unit tests for the PITA::Report::Platform class

use strict;
use lib ();
use UNIVERSAL 'isa';
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	unless ( $ENV{HARNESS_ACTIVE} ) {
		require FindBin;
		$FindBin::Bin = $FindBin::Bin; # Avoid a warning
		chdir catdir( $FindBin::Bin, updir() );
		lib->import('blib', 'lib');
	}
}

use Test::More tests => 3;
use PITA::Report ();

# The easiest test to do is to get the current platform
my $current = PITA::Report::Platform->current;
isa_ok( $current, 'PITA::Report::Platform' );
is( $current->osname,   $^O, '->osname matches expected'   );
is( $current->perlpath, $^X, '->perlpath matches expected' );

exit(0);
