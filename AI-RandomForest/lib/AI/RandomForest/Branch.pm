package AI::RandomForest::Branch;

use strict;
use warnings;

our $VERSION = '0.01';





######################################################################
# Constructor and Accessors

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	return $self;
}

sub variable {
	$_[0]->{variable};
}

sub separator {
	$_[0]->{separator};
}

sub left {
	$_[0]->{left};
}

sub right {
	$_[0]->{right};
}





######################################################################
# Main Methods

sub as_string {
	print "Branch: $_[0]->{feature} > $_[0]->{separator}";
}

1;
