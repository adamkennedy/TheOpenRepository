package RLike::Vector;

=pod

=head1 NAME

RLike::Vector - The implementation of a vector in RLike

=head1 DESCRIPTION

This class implements functionality for vectors.

This package should not be used directly by programs implemented in
L<RLike>. It is documented for those implementing  L<RLike> itself.

=head1 METHODS

=cut

use 5.008;
use strict;
use warnings;
use Carp;
use Params::Util qw{ _INSTANCE };

our $VERSION = '0.01';

=pod

=head2 new

The C<new> constructor takes a simple list of scalars and created an object
representing an R like vector.

It validates none of the parameters, and like all methods in the
B<RLike::Vector> package should not be used directly.

=cut

sub new {
	my $class = shift;
	return bless [ @_ ], $class;
}

sub list {
	my $self = shift;
	return @$self;
}

sub length {
	my $self = shift;
	return RLike::Vector->new(
		scalar @$self
	);
}

sub max {
	my $self = shift;
	return RLike::Vector->new(
		List::Util::max(@$self)
	);
}

sub min {
	my $self = shift;
	return RLike::Vector->new(
		List::Util::min(@$self)
	);
}

sub range {
	my $self = shift;
	return RLike::Vector->new(
		List::Util::min(@$self),
		List::Util::max(@$self),
	);
}

sub sum {
	my $self = shift;
	return RLike::Vector->new(
		List::Util::sum(@$self)
	);
}

sub mean {
	my $self = shift;
	return RLike::Vector->new(
		List::Util::sum(@$self) / scalar(@$self)
	);
}

sub var {
	my $self = shift;
	my $mean = List::Util::sum(@$self) / scalar(@$self);
	return RLike::Vector->new(
		List::Util::sum(
			map { ($_ - $mean) ^ 2 } @$self
		) / $#$self
	);
}

sub log {
	die "RLike only supports natural log" if @_ > 1;
	my $self = shift;
	return RLike::Vector->new(
		map { CORE::log($_) } @$self
	);
}

sub sin {
	my $self = shift;
	return RLike::Vector->new(
		map { CORE::sin($_) } @$self
	);
}

sub cos {
	my $self = shift;
	return RLike::Vector->new(
		map { CORE::cos($_) } @$self
	);
}

sub tan {
	my $self = shift;
	return RLike::Vector->new(
		map { CORE::sin($_) / CORE::cos($_) } @$self
	);
}

sub sqrt {
	my $self = shift;
	return RLike::Vector->new(
		map { CORE::sqrt($_) } @$self
	);
}

sub add {
	ASSERT_SIMILAR(@_);
	my $l  = shift;
	my $r  = shift;
	my $ln = scalar @$l;
	my $rn = scalar @$r;
	return RLike::Vector->new(
		map {
			$l->[ $_ % $ln ] + $r->[ $_ % $rn ]
		} ( 0 .. List::Util::max($#$l, $#$r) )
	);
}

sub subtract {
	ASSERT_SIMILAR(@_);
	my $l  = shift;
	my $r  = shift;
	my $ln = scalar @$l;
	my $rn = scalar @$r;
	return RLike::Vector->new(
		map {
			$l->[ $_ % $ln ] - $r->[ $_ % $rn ]
		} ( 0 .. List::Util::max($#$l, $#$r) )
	);
}

sub multiply {
	ASSERT_SIMILAR(@_);
	my $l  = shift;
	my $r  = shift;
	my $ln = scalar @$l;
	my $rn = scalar @$r;
	return RLike::Vector->new(
		map {
			$l->[ $_ % $ln ] * $r->[ $_ % $rn ]
		} ( 0 .. List::Util::max($#$l, $#$r) )
	);
}

sub divide {
	ASSERT_SIMILAR(@_);
	my $l  = shift;
	my $r  = shift;
	my $ln = scalar @$l;
	my $rn = scalar @$r;
	return RLike::Vector->new(
		map {
			$l->[ $_ % $ln ] / $r->[ $_ % $rn ]
		} ( 0 .. List::Util::max($#$l, $#$r) )
	);
}

sub raise {
	ASSERT_SIMILAR(@_);
	my $l  = shift;
	my $r  = shift;
	my $ln = scalar @$l;
	my $rn = scalar @$r;
	return RLike::Vector->new(
		map {
			$l->[ $_ % $ln ] ^ $r->[ $_ % $rn ]
		} ( 0 .. List::Util::max($#$l, $#$r) )
	);
}

sub sort {
	my $self = shift;
	return RLike::Vector->new(
		CORE::sort @$self
	);
}





######################################################################
# Support Functions

sub ASSERT_SIMILAR {
	unless ( Params::Util::_INSTANCE($_[0], __PACKAGE__) ) {
		croak('Left operand is not a vector');
	}
	unless ( Params::Util::_INSTANCE($_[1], __PACKAGE__) ) {
		croak('Right operand is not a vector');
	}
	my $long  = scalar @{$_[0]};
	my $short = scalar @{$_[0]};
	if ( $long >= $short ) {
		$long % $short or return;
	} else {
		$short % $long or return;
	}
	warn("longer object length is not a multiple of shorter object length");
}

1;

=pod

=head1 SUPPORT

See the main module L<RLike> for support information.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2012 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
