package Aspect::Point::Around;

use strict;
use warnings;
use Aspect::Point ();

our $VERSION = '0.97';
our @ISA     = 'Aspect::Point';

use constant type => 'around';

sub exception {
	my $self = shift;
	return $self->{exception} unless @_;
	$self->{proceed}   = 0;
	$self->{exception} = shift;
}

sub original {
	$_[0]->{original};
}

1;
