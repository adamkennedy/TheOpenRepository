#!/usr/bin/perl -w

# Load testing for CGI::Capture

use strict;
use lib ();
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	unless ( $ENV{HARNESS_ACTIVE} ) {
		require FindBin;
		chdir ($FindBin::Bin = $FindBin::Bin); # Avoid a warning
		lib->import( catdir(updir(), 'lib') );
	}
}

use Test::More tests => 2;

# Check their perl version
ok( $] >= 5.006, "Your perl is new enough" );

# Does the module load
use_ok('CGI::Capture');

exit(0);
