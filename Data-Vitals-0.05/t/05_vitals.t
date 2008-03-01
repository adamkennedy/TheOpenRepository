#!/usr/bin/perl -w

# Unit testing for Data::Vitals

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

use Test::More tests => 28;
use Data::Vitals;





#####################################################################
# Constructor

foreach my $test (
	[ 'height',   '180cm',  "5'10\"" ],
	[ 'hips',     '80cm',   '31"'    ],
	[ 'waist',    '81cm',   '31.5"'  ],
	[ 'frame',    '82cm',   '32"'    ],
	[ 'chest',    '84.5cm', '33"'    ],
	[ 'bust',     '86cm',   '33.5"'  ],
	[ 'underarm', '88.5cm', '34.5"'  ],
) {
	# Create the measurement
	my $method = $test->[0];
	my $value  = $test->[1];
	my $Measurement = Data::Vitals->$method($value);

	# Is it what we expected
	my $class  = "Data::Vitals::" . ucfirst($method);
	$class =~ s/Bust/Chest/;
	isa_ok( $Measurement, $class );

	# Does the string form match the provided value
	is( $Measurement->as_string, $value, '->as_string returns the original value correctly' );
	is( $Measurement->as_metric, $value, '->as_metric returns the same value' );

	# Does the imperial form match the expected value
	my $imperial = $test->[2];
	is( $Measurement->as_imperial, $imperial, '->as_imperial returns the expected value' );
}

exit(0);
