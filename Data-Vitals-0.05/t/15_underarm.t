#!/usr/bin/perl -w

# Unit testing for Data::Vitals::Underarm

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
use Data::Vitals::Underarm;





#####################################################################
# Constructor

my $Underarm = Data::Vitals::Underarm->new('38"');
isa_ok( $Underarm, 'Data::Vitals::Underarm' );
is( $Underarm->as_string,   '97cm', 'Returned correct string form'   );
is( $Underarm->as_metric,   '97cm', 'Returned correct metric form'   );
is( $Underarm->as_imperial, '38"',  'Returned correct imperial form' );
is( $Underarm->as_cms,      '97cm', 'Returned correct cm size'       );
is( $Underarm->as_inches,   '38"',  'Returned original size'         );

exit(0);