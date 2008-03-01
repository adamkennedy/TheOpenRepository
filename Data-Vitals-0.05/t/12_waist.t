#!/usr/bin/perl -w

# Unit testing for Data::Vitals::Waist

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
use Data::Vitals::Waist;





#####################################################################
# Constructor

my $Waist = Data::Vitals::Waist->new('38"');
isa_ok( $Waist, 'Data::Vitals::Waist' );
is( $Waist->as_string,   '97cm', 'Returned correct string form'   );
is( $Waist->as_metric,   '97cm', 'Returned correct metric form'   );
is( $Waist->as_imperial, '38"',  'Returned correct imperial form' );
is( $Waist->as_cms,      '97cm', 'Returned correct cm size'       );
is( $Waist->as_inches,   '38"',  'Returned original size'         );

exit(0);