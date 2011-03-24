package Aspect::Point::Around;

use strict;
use warnings;
use Aspect::Point ();

our $VERSION = '0.97';
our @ISA     = 'Aspect::Point';

use constant type => 'around';

sub original {
	$_[0]->{original};
}

sub exception {
	my $self = shift;
	return $self->{exception} unless @_;
	$self->{proceed}   = 0;
	$self->{exception} = shift;
}

sub proceed {
	my $self = shift;

	return $self->return_value(
		Sub::Uplevel::uplevel(
			2,
			$self->{original},
			@{$self->{params}},
		)
	) if $self->{wantarray};

	return $self->return_value(
		scalar Sub::Uplevel::uplevel(
			2,
			$self->{original},
			@{$self->{params}},
		)
	) if defined $self->{wantarray};

	return Sub::Uplevel::uplevel(
		2,
		$self->{original},
		@{$self->{params}},
	);
}

BEGIN {
	*run_original = *proceed;
}

1;
