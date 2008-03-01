#!/usr/bin/perl -w

# Unit testing for Data::Vitals::Chest

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
use Data::Vitals::Chest;





#####################################################################
# Constructor

my $Chest = Data::Vitals::Chest->new('38"');
isa_ok( $Chest, 'Data::Vitals::Chest' );
is( $Chest->as_string,   '97cm', 'Returned correct string form'   );
is( $Chest->as_metric,   '97cm', 'Returned correct metric form'   );
is( $Chest->as_imperial, '38"',  'Returned correct imperial form' );
is( $Chest->as_cms,      '97cm', 'Returned correct cm size'       );
is( $Chest->as_inches,   '38"',  'Returned original size'         );

exit(0);