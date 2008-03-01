#!/usr/bin/perl -w

# Unit testing for Data::Vitals::Frame

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

use Test::More tests => 6;
use Data::Vitals::Frame;





#####################################################################
# Constructor

my $Frame = Data::Vitals::Frame->new('38"');
isa_ok( $Frame, 'Data::Vitals::Frame' );
is( $Frame->as_string,   '97cm', 'Returned correct string form'   );
is( $Frame->as_metric,   '97cm', 'Returned correct metric form'   );
is( $Frame->as_imperial, '38"',  'Returned correct imperial form' );
is( $Frame->as_cms,      '97cm', 'Returned correct cm size'       );
is( $Frame->as_inches,   '38"',  'Returned original size'         );

exit(0);