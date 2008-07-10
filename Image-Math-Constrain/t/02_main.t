#!/usr/bin/perl -w

# Main functional testing for Image::Math::Constrain

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

use Test::More tests => 47;
use Image::Math::Constrain;





#####################################################################
# Constructor Testing

sub ok_constrain {
	my $expected = shift;
	my @params   = @_;
	my $Math = Image::Math::Constrain->new( @params );
	isa_ok( $Math, 'Image::Math::Constrain' );
	is( $Math->{width},  $expected->[0], '->{width} is correct'  );
	is( $Math->width,    $expected->[0], '->width is correct'    );
	is( $Math->{height}, $expected->[1], '->{height} is correct' );
	is( $Math->height,   $expected->[1], '->height is correct'   );
}

# A zillion variants of the legal way to create a new constrain object
my @tests = (
	[ [ 800, 600 ], 800, 600             ],
	[ [ 800, 600 ], 800, 600             ],
	[ [ 800, 600 ], [ 800, 600 ]         ],
	[ [ 800, 600 ], 'constrain(800x600)' ],
	[ [ 800, 600 ], '800x600'            ],
	[ [ 800, 600 ], '800w600h'           ],
	[ [ 800, 0   ], '800w'               ],
	[ [ 0,   0   ], '0x0'                ],
	);

foreach my $test ( @tests ) {
	ok_constrain( @$test );
}





#####################################################################
# Test the actual constraining

my $Math = Image::Math::Constrain->new( 80, 100 );
isa_ok( $Math, 'Image::Math::Constrain' );

my @list = $Math->constrain( 800, 600 );
my $hash = $Math->constrain( 800, 600 );

is_deeply( \@list, [ 80, 60, 0.1 ], '->constrain returns correctly in list context' );
is_deeply( $hash, { width => 80, height => 60, scale => 0.1 },
	'->constrain returns correctly in scalar context' );

@list = $Math->constrain( 40, 60 );
is_deeply( \@list, [ 40, 60, 1 ], '->constrain returns correctly in list context' );





# Other miscellaneous things
ok( $Math, 'An object is true' );
is( $Math->as_string, 'constrain(80x100)', '->as_string works correctly' );
is( "$Math", 'constrain(80x100)', '->as_string is the auto-stringification method' );

exit(0);
