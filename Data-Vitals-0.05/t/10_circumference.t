#!/usr/bin/perl -w

# Unit testing for Data::Vitals::Circumference

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
use Data::Vitals::Circumference;





#####################################################################
# Constructor

my $Circumference = Data::Vitals::Circumference->new('38"');
isa_ok( $Circumference, 'Data::Vitals::Circumference' );
is( $Circumference->as_string,   '97cm', 'Returned correct string form'   );
is( $Circumference->as_metric,   '97cm', 'Returned correct metric form'   );
is( $Circumference->as_imperial, '38"',  'Returned correct imperial form' );
is( $Circumference->as_cms,      '97cm', 'Returned correct cm size'       );
is( $Circumference->as_inches,   '38"',  'Returned original size'         );

exit(0);