#!/usr/bin/perl -T

# Full testing for Chart::Math::Axis

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 165;
use Math::BigInt;
use Math::BigFloat;
use Chart::Math::Axis;





#####################################################################
# Preparation

my $Interval = Math::BigFloat->new( 5     );
my $First    = Math::BigFloat->new( 4     );
my $Second   = Math::BigFloat->new( 1.3   );
my $Third    = Math::BigFloat->new( 0     );
my $Fourth   = Math::BigFloat->new( 0.001 );
my $Fifth    = Math::BigFloat->new( -1.3  );
my $Sixth    = Math::BigFloat->new( -5    );





#####################################################################
# Test all the private math stuff first

# Chart::Math::Axis->_round_top
ok( Chart::Math::Axis->_round_top( 4, 5 ) == 5, "->_round_top( 4, 5 )" );
ok( Chart::Math::Axis->_round_top( 1.3, 5 ) == 5, "->_round_top( 1.3, 5 )" );
ok( Chart::Math::Axis->_round_top( 0, 5 ) == 5, "->_round_top( 0, 5 )" );
ok( Chart::Math::Axis->_round_top( 0.001, 5 ) == 5, "->_round_top( 0.001, 5 )" );
ok( Chart::Math::Axis->_round_top( -1.3, 5 ) == 0, "->_round_top( -1.3, 5 )" );
ok( Chart::Math::Axis->_round_top( -5, 5 ) == 0, "->_round_top( -5, 5 )" );

ok( Chart::Math::Axis->_round_top( $First, 5 ) == 5, "->_round_top( 4, 5 )" );
ok( Chart::Math::Axis->_round_top( $Second, 5 ) == 5, "->_round_top( 1.3, 5 )" );
ok( Chart::Math::Axis->_round_top( $Third, 5 ) == 5, "->_round_top( 0, 5 )" );
ok( Chart::Math::Axis->_round_top( $Fourth, 5 ) == 5, "->_round_top( 0.001, 5 )" );
ok( Chart::Math::Axis->_round_top( $Fifth, 5 ) == 0, "->_round_top( -1.3, 5 )" );
ok( Chart::Math::Axis->_round_top( $Sixth, 5 ) == 0, "->_round_top( -5, 5 )" );

ok( Chart::Math::Axis->_round_top( 4, $Interval ) == 5, "->_round_top( 4, 5 )" );
ok( Chart::Math::Axis->_round_top( 1.3, $Interval ) == 5, "->_round_top( 1.3, 5 )" );
ok( Chart::Math::Axis->_round_top( 0, $Interval ) == 5, "->_round_top( 0, 5 )" );
ok( Chart::Math::Axis->_round_top( 0.001, $Interval ) == 5, "->_round_top( 0.001, 5 )" );
ok( Chart::Math::Axis->_round_top( -1.3, $Interval ) == 0, "->_round_top( -1.3, 5 )" );
ok( Chart::Math::Axis->_round_top( -5, $Interval ) == 0, "->_round_top( -5, 5 )" );

ok( Chart::Math::Axis->_round_top( $First, $Interval ) == 5, "->_round_top( 4, 5 )" );
ok( Chart::Math::Axis->_round_top( $Second, $Interval ) == 5, "->_round_top( 1.3, 5 )" );
ok( Chart::Math::Axis->_round_top( $Third, $Interval ) == 5, "->_round_top( 0, 5 )" );
ok( Chart::Math::Axis->_round_top( $Fourth, $Interval ) == 5, "->_round_top( 0.001, 5 )" );
ok( Chart::Math::Axis->_round_top( $Fifth, $Interval ) == 0, "->_round_top( -1.3, 5 )" );
ok( Chart::Math::Axis->_round_top( $Sixth, $Interval ) == 0, "->_round_top( -5, 5 )" );

# Chart::Math::Axis->_round_bottom
ok( Chart::Math::Axis->_round_bottom( 4, 5 ) == 0, "->_round_bottom( 4, 5 )" );
ok( Chart::Math::Axis->_round_bottom( 1.3, 5 ) == 0, "->_round_bottom( 1.3, 5 )" );
ok( Chart::Math::Axis->_round_bottom( 0, 5 ) == 0, "->_round_bottom( 0, 5 )" );
ok( Chart::Math::Axis->_round_bottom( 0.001, 5 ) == 0, "->_round_bottom( 0.001, 5 )" );
ok( Chart::Math::Axis->_round_bottom( -1.3, 5 ) == -5, "->_round_bottom( -1.3, 5 )" );
ok( Chart::Math::Axis->_round_bottom( -5, 5 ) == -10, "->_round_bottom( -5, 5 )" );

ok( Chart::Math::Axis->_round_bottom( $First, 5 ) == 0, "->_round_bottom( 4, 5 )" );
ok( Chart::Math::Axis->_round_bottom( $Second, 5 ) == 0, "->_round_bottom( 1.3, 5 )" );
ok( Chart::Math::Axis->_round_bottom( $Third, 5 ) == 0, "->_round_bottom( 0, 5 )" );
ok( Chart::Math::Axis->_round_bottom( $Fourth, 5 ) == 0, "->_round_bottom( 0.001, 5 )" );
ok( Chart::Math::Axis->_round_bottom( $Fifth, 5 ) == -5, "->_round_bottom( -1.3, 5 )" );
ok( Chart::Math::Axis->_round_bottom( $Sixth, 5 ) == -10, "->_round_bottom( -5, 5 )" );

ok( Chart::Math::Axis->_round_bottom( 4, $Interval ) == 0, "->_round_bottom( 4, 5 )" );
ok( Chart::Math::Axis->_round_bottom( 1.3, $Interval ) == 0, "->_round_bottom( 1.3, 5 )" );
ok( Chart::Math::Axis->_round_bottom( 0, $Interval ) == 0, "->_round_bottom( 0, 5 )" );
ok( Chart::Math::Axis->_round_bottom( 0.001, $Interval ) == 0, "->_round_bottom( 0.001, 5 )" );
ok( Chart::Math::Axis->_round_bottom( -1.3, $Interval ) == -5, "->_round_bottom( -1.3, 5 )" );
ok( Chart::Math::Axis->_round_bottom( -5, $Interval ) == -10, "->_round_bottom( -5, 5 )" );

ok( Chart::Math::Axis->_round_bottom( $First, $Interval ) == 0, "->_round_bottom( 4, 5 )" );
ok( Chart::Math::Axis->_round_bottom( $Second, $Interval ) == 0, "->_round_bottom( 1.3, 5 )" );
ok( Chart::Math::Axis->_round_bottom( $Third, $Interval ) == 0, "->_round_bottom( 0, 5 )" );
ok( Chart::Math::Axis->_round_bottom( $Fourth, $Interval ) == 0, "->_round_bottom( 0.001, 5 )" );
ok( Chart::Math::Axis->_round_bottom( $Fifth, $Interval ) == -5, "->_round_bottom( -1.3, 5 )" );
ok( Chart::Math::Axis->_round_bottom( $Sixth, $Interval ) == -10, "->_round_bottom( -5, 5 )" );

# Chart::Math::Axis->_order_of_magnitude
ok( Chart::Math::Axis->_order_of_magnitude( 4 ) == 0, "->_order_of_magnitude( 4 )" );
ok( Chart::Math::Axis->_order_of_magnitude( $First ) == 0, "->_order_of_magnitude( 4 )" );
ok( Chart::Math::Axis->_order_of_magnitude( 1.3 ) == 0, "->_order_of_magnitude( 1.3 )" );
ok( Chart::Math::Axis->_order_of_magnitude( $Second ) == 0, "->_order_of_magnitude( 1.3 )" );
ok( Chart::Math::Axis->_order_of_magnitude( 0 ) == 0, "->_order_of_magnitude( 0 )" );
ok( Chart::Math::Axis->_order_of_magnitude( $Third ) == 0, "->_order_of_magnitude( 0 )" );
ok( Chart::Math::Axis->_order_of_magnitude( 0.001 ) == -3, "->_order_of_magnitude( 0.001 )" );
ok( Chart::Math::Axis->_order_of_magnitude( $Fourth ) == -3, "->_order_of_magnitude( 0.001 )" );
ok( Chart::Math::Axis->_order_of_magnitude( -1.3 ) == 0, "->_order_of_magnitude( -1.3 )" );
ok( Chart::Math::Axis->_order_of_magnitude( $Fifth ) == 0, "->_order_of_magnitude( -1.3 )" );

ok( Chart::Math::Axis->_order_of_magnitude( 10 ) == 1, "->_order_of_magnitude( 10 )" );
ok( Chart::Math::Axis->_order_of_magnitude( 0.1 ) == -1, "->_order_of_magnitude( 0.1 )" );
ok( Chart::Math::Axis->_order_of_magnitude( 50000 ) == 4, "->_order_of_magnitude( 50000 )" );

# Chart::Math::Axis->_reduce_interval
my $Reduced1 = Chart::Math::Axis->_reduce_interval( $Interval );
my $Reduced2 = Chart::Math::Axis->_reduce_interval( 5 );
isa_ok( $Interval, 'Math::BigFloat' );
ok( $Interval == 5, "->_reduce_interval doesn't alter argument" );
isa_ok( $Reduced1, 'Math::BigFloat' );
isa_ok( $Reduced2, 'Math::BigFloat' );
ok( $Reduced1 == 2, '->_reduce_interval( 5 )' );
ok( $Reduced2 == 2, '->_reduce_interval( 5 )' );
ok( Chart::Math::Axis->_reduce_interval( 100 ) == 50, '->_reduce_interval( 100 )' );
ok( Chart::Math::Axis->_reduce_interval( 50 ) == 20, '->_reduce_interval( 50 )' );
ok( Chart::Math::Axis->_reduce_interval( 20 ) == 10, '->_reduce_interval( 20 )' );
ok( Chart::Math::Axis->_reduce_interval( 10 ) == 5, '->_reduce_interval( 10 )' );
ok( Chart::Math::Axis->_reduce_interval( 2 ) == 1, '->_reduce_interval( 2 )' );
ok( Chart::Math::Axis->_reduce_interval( 1 ) == 0.5, '->_reduce_interval( 1 )' );
ok( Chart::Math::Axis->_reduce_interval( 0.5 ) == 0.2, '->_reduce_interval( 0.5 )' );
ok( Chart::Math::Axis->_reduce_interval( 0.2 ) == 0.1, '->_reduce_interval( 0.2 )' );
ok( Chart::Math::Axis->_reduce_interval( 0.1 ) == 0.05, '->_reduce_interval( 0.1 )' );





#####################################################################
# Test the constructor and basic access methods
my $Axis = Chart::Math::Axis->new();
isa_ok( $Axis, 'Chart::Math::Axis' );
ok( ! defined $Axis->max, '->max returns undef for empty object' );
ok( ! defined $Axis->min, '->min returns undef for empty object' );
ok( ! defined $Axis->top, '->top returns undef for empty object' );
ok( ! defined $Axis->bottom, '->bottom returns undef for empty object' );
ok( ! defined $Axis->interval_size, '->interval_size returns undef for empty object' );
ok( ! defined $Axis->ticks, '->ticks returns undef for empty object' );

# Throw a battery of constructor cases at it
$Axis = Chart::Math::Axis->new( 10, 20 );
test_this( $Axis, 'new simple case', [ 20, 10, 22, 8, 2, 7 ] );

$Axis = Chart::Math::Axis->new( 20, 10 );
test_this( $Axis, 'new reversed simple case', [ 20, 10, 22, 8, 2, 7 ] );

$Axis = Chart::Math::Axis->new( 0, -10 );
test_this( $Axis, 'new negative zero border case', [ 0, -10, 2, -12, 2, 7 ] );

$Axis = Chart::Math::Axis->new( 5, -5 );
test_this( $Axis, 'zero spanning case', [ 5, -5, 6, -6, 2, 6 ] );

$Axis = Chart::Math::Axis->new( 10, 0 );
test_this( $Axis, 'new positive zero border case', [ 10, 0, 12, 0, 2, 6 ] );

$Axis = Chart::Math::Axis->new( 1.12 );
test_this( $Axis, 'new single value case', [ 1.12, 1.12, 2, 1, 0.1, 10 ] );

$Axis = Chart::Math::Axis->new( 10 );
test_this( $Axis, 'single value case with 1 digit mantissa', [ 10, 10, 20, 0, 2, 10 ] );

$Axis = Chart::Math::Axis->new( 0 );
test_this( $Axis, 'single value case of 0', [ 0, 0, 1, 0, 1, 1 ] );

$Axis = Chart::Math::Axis->new( -1.12 );
test_this( $Axis, 'negative single value case', [ -1.12, -1.12, -1, -2, 0.1, 10 ] );

$Axis = Chart::Math::Axis->new( -10 );
test_this( $Axis, 'negative single value case with 1 digit mantissa', [ -10, -10, 0, -20, 2, 10 ] );





###############################################################################
# Test the modification methods

$Axis = Chart::Math::Axis->new( 10 );
ok( $Axis->add_data( 0 ), "->add_data returns true" );
ok( all_correct( $Axis, [ 10, 0, 12, 0, 2, 6 ] ), "->add_data changes the Axis correctly" );

$Axis = Chart::Math::Axis->new( 10 );
ok( $Axis->include_zero, "->include_zero returns true" );
ok( all_correct( $Axis, [ 10, 0, 12, 0, 2, 6 ] ), "->include_zero changes the Axis correctly" );

$Axis = Chart::Math::Axis->new( 5, -5 );
ok( $Axis->include_zero, "->include_zero returns true for zero spanning case" );
ok( all_correct( $Axis, [ 5, -5, 6, -6, 2, 6 ] ), "->include_zero doesn't affect zero spanning case" );

$Axis = Chart::Math::Axis->new( -10 );
ok( $Axis->include_zero, "->include_zero returns true for negative case" );
ok( all_correct( $Axis, [ 0, -10, 2, -12, 2, 7 ] ), "->include_zero works for negative case" );

$Axis = Chart::Math::Axis->new( 10, 0 );
ok( $Axis->maximum_intervals == 10, "Default maximum_intervals is correct" );
ok( $Axis->set_maximum_intervals( 13 ), "->set_maximum_intervals returns true" );
ok( $Axis->maximum_intervals == 13, "->set_maximum_intervals appears to change maximum_intervals" );
ok( all_correct( $Axis, [ 10, 0, 11, 0, 1, 11 ] ), "->set_maximum_intervals adjust intervals as expected" );

# Heaps more tests to complete
### FINISH ME



















# Function to test the properties of an Axis object
sub test_this {
	my $Axis = shift;
	my $description = shift;
	my $test = shift;

	isa_ok( $Axis, 'Chart::Math::Axis' );
	ok( $Axis->max == $test->[0], "->max returns correct for $description" );
	ok( $Axis->min == $test->[1], "->min returns correct for $description" );
	ok( $Axis->top == $test->[2], "->top returns correct for $description" );
	ok( $Axis->bottom == $test->[3], "->bottom returns correct for $description" );
	ok( $Axis->interval_size == $test->[4], "->interval_size returns correct for $description" );
	ok( $Axis->ticks == $test->[5], "->ticks returns correct for $description" );
}

sub all_correct {
	my $Axis = shift;
	my $test = shift;

	return undef unless $Axis->isa('Chart::Math::Axis');
	return undef unless $Axis->max == $test->[0];
	return undef unless $Axis->min == $test->[1];
	return undef unless $Axis->top == $test->[2];
	return undef unless $Axis->bottom == $test->[3];
	return undef unless $Axis->interval_size == $test->[4];
	return undef unless $Axis->ticks == $test->[5];

	return 1;
}

1;
