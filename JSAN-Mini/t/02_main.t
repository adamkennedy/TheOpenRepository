#!/usr/bin/perl -w

# Test what little we can of JSAN::Mini

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

use JSAN::Mini ();
use Test::More tests => 2;

my $mini = JSAN::Mini->new;
isa_ok( $mini, 'JSAN::Mini' );

# Get the release list
my @releases = $mini->_releases;
ok( scalar(@releases), 'Got release update list' );

exit(0);
