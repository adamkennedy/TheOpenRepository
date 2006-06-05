#!/usr/bin/perl -w

# Main (and basic) testing for PITA::Test::Image::Qemu

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
			);
	}
}

use Test::More tests => 3;

ok( $] > 5.005, 'Perl version is 5.005 or newer' );

use_ok( 'PITA::Test::Image::Qemu' );

my $file = PITA::Test::Image::Qemu->filename;
ok( -f $file, '->filename returns file that exists' );

exit(0);
