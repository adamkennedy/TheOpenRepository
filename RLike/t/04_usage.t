#!/usr/bin/perl

# Test the practical usage of RLike

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}
use Test::More tests => 3;
use Test::NoWarnings;
use RLike;





######################################################################
# Metrics

sub root_mean_squared {
	my $vector = shift;
	mean( $vector->raise( c(2) ) )->sqrt;
}

sub root_mean_squared_error {
	my $actual = shift;
	my $predicted = shift;
	root_mean_squared( $predicted->subtract($actual) );
}

my $want = c(1, 2, 3);
my $have = c(2, 2, 2);
my $rmse = root_mean_squared_error( $want, $have );
ok( $rmse->[0] > 0.81, 'rmse ok' );
ok( $rmse->[0] < 0.82, 'rmse ok' );
