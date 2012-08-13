package AI::RandomForest::Branch;

use strict;
use warnings;

our $VERSION = '0.01';





######################################################################
# Constructor and Accessors

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Apply defaults and check params
	$self->{nleft}  ||= 0;
	$self->{nright} ||= 0;

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

sub nleft {
	$_[0]->{nleft};
}

sub nright {
	$_[0]->{nright};
}

1;
