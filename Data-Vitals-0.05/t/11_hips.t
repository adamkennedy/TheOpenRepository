#!/usr/bin/perl -w

# Unit testing for Data::Vitals::Hips

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
use Data::Vitals::Hips;





#####################################################################
# Constructor

my $Hips = Data::Vitals::Hips->new('38"');
isa_ok( $Hips, 'Data::Vitals::Hips' );
is( $Hips->as_string,   '97cm', 'Returned correct string form'   );
is( $Hips->as_metric,   '97cm', 'Returned correct metric form'   );
is( $Hips->as_imperial, '38"',  'Returned correct imperial form' );
is( $Hips->as_cms,      '97cm', 'Returned correct cm size'       );
is( $Hips->as_inches,   '38"',  'Returned original size'         );

exit(0);