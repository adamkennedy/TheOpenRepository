package AI::RandomForest::Selection;

use 5.16.0;
use strict;
use warnings;
use List::Util 'sum';

our $VERSION = '0.01';

sub new {
	my $class = shift;
	my $self  = bless {
		index => $_[0],
		datum => $_[1],
	}, $class;
	
	return $self;
}





######################################################################
# Math Stuff

# Gini calculation (variables and method based on R implementation)
# The set is assumed to be sorted in advance.
sub gini1 {
	my $x = shift;

	# n <- length(x)
	my $n = scalar @$x;

	# x <- sort(x)
	# (Not needed, it is sorted in advance)

	# G <- sum(x * 1:n)
	my $G = 0;
	foreach my $i ( 1 .. $n ) {
		$G += $i * $x->[$i - 1];
	}

	# G <- 2 * G/(n * sum(x))
	$G = 2 * $G / ($n * sum(@$x));

	# G - 1 - (1/n)
	$G - 1 - (1/$n);
}

1;
