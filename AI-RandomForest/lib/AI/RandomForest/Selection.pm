package AI::RandomForest::Selection;

use 5.16.0;
use strict;
use warnings;

our $VERSION = '0.01';

sub new {
	my $class = shift;
	my $self  = bless {
		index => $_[0],
		datum => $_[1],
	}, $class;

	return $self;
}

1;
