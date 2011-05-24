package Aspect::Point::Around;
=pod

=head1 NAME

Aspect::Point - The Join Point context for "around" advice code

=head1 SYNOPSIS

=head1 METHODS

=cut

use strict;
use warnings;
use Aspect::Point ();

our $VERSION = '0.99';
our @ISA     = 'Aspect::Point';

use constant type => 'around';

sub return_value {
	my $self = shift;
	my $want = $self->{wantarray};

	# Handle usage in getter form
	if ( defined CORE::wantarray() ) {
		# Let the inherent magic of Perl do the work between the
		# list and scalar context calls to return_value
		return @{$self->{return_value}} if $want;
		return   $self->{return_value}  if defined $want;
		return;
	}

	# We've been provided a return value
	if ( $want ) {
		@{$self->{return_value}} = @_;
	} elsif ( defined $want ) {
		$self->{return_value} = pop;
	}
}

sub proceed {
	my $self = shift;

	return $self->return_value(
		Sub::Uplevel::uplevel(
			2,
			$self->{original},
			@{$self->{args}},
		)
	) if $self->{wantarray};

	return $self->return_value(
		scalar Sub::Uplevel::uplevel(
			2,
			$self->{original},
			@{$self->{args}},
		)
	) if defined $self->{wantarray};

	return Sub::Uplevel::uplevel(
		2,
		$self->{original},
		@{$self->{args}},
	);
}

BEGIN {
	*run_original = *proceed;
}

1;

=pod

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

Marcel GrE<uuml>nauer E<lt>marcel@cpan.orgE<gt>

Ran Eilam E<lt>eilara@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2001 by Marcel GrE<uuml>nauer

Some parts copyright 2009 - 2011 Adam Kennedy.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
