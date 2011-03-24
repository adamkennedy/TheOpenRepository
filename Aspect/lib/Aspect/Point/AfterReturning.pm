package Aspect::Point::AfterReturning;

use strict;
use warnings;
use Aspect::Point ();

our $VERSION = '0.97_01';
our @ISA     = 'Aspect::Point';

use constant type => 'after_returning';

sub exception {
	my $self = shift;
	return $self->{exception} unless @_;
	$self->{proceed}   = 0;
	$self->{exception} = shift;
}

1;
