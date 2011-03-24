package Aspect::Point::Before;

use strict;
use warnings;
use Aspect::Point ();

our $VERSION = '0.96';
our @ISA     = 'Aspect::Point';

sub type { 'before' }

sub exception {
	my $self = shift;
	if ( @_ ) {
		$self->{exception} = shift;
		$self->{proceed}   = 0;
	}
	$self->{exception};
}

sub original {
	$_[0]->{original};
}

1;
