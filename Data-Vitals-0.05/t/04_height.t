#!/usr/bin/perl -w

# Unit testing for Data::Vitals::Height

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
use Data::Vitals::Height;





#####################################################################
# Constructor

my $Height = Data::Vitals::Height->new("6'0\"");
isa_ok( $Height, 'Data::Vitals::Height' );
is( $Height->as_string,   '183cm', 'Returned correct string form'    );
is( $Height->as_metric,   '183cm', 'Returned correct metric value'   );
is( $Height->as_imperial, "6'0\"", 'Returned correct imperial value' );
is( $Height->as_cms,      '183cm', 'Returned correct cm size'        );
is( $Height->as_feet,     "6'0\"", 'Returned original size'          );

exit(0);