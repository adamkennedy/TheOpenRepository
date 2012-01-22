package RLike;

=pod

=head1 NAME

RLike - Experimental module that provides an R-like pseudo language

=head1 SYNOPSIS

  use RLike;
  
  $x = c(1, 2, 3);

=head1 DESCRIPTION

B<RLike> implements an experimental pseudo-language with a style similar
to the R programming language.

It has been created to explore the use and style of a language where the
fundamental variables are vectors, as with R.

=head1 COMMANDS

In R, functions that can be called by name are known as commands.

=cut

use 5.008;
use strict;
use warnings;
use Exporter          ();
use List::Util   1.19 ();
use Params::Util 1.00 ();
use RLike::Vector     ();

our $VERSION = '0.01';
our @ISA     = 'Exporter';
our @EXPORT  = qw{ c max min range length sum mean var };

=pod

=head2 c

The C<c> command creates a vector from a list of elements.

If any of the elements in the list are themselves a vector they will be
unrolled to produce a single list containing the elements of all of them.

=cut

sub c {
	return undef unless @_;
	RLike::Vector->new(
		map {
			Params::Util::_INSTANCE($_, 'RLike::Vector') ? @$_ : $_
		} @_
	);
}

=pod

=head2 length

  my $l = length($v);

The C<length> command returns the number of elements in a vector.

=cut

sub length {
	shift->length;
}

=pod

=head2 max

  my $max = max($v);

The C<max> command returns the maximum value from the elements in a vector.

=cut

sub max {
	shift->max;
}

=pod

=head2 min

  my $min = min($v);

The C<min> command returns the minimum value from the elements in a vector.

=cut

sub min {
	shift->min;
}

=pod

=head2 range

  my $range = range($v);
  my $min   = $range->[0];
  my $max   = $range->[1];

The C<range> command returns a two-element vector contains the minimum and
maximum values from the elements in a vector.

=cut

sub range {
	shift->range;
}

=pod

=head2 sum

  my $total = sum($v);

The C<sum> command returns the total of the elements in a vector added
together.

=cut

sub sum {
	shift->sum;
}

=pod

=head2 mean

  my $average = mean($v);

The C<mean> command returns the average value of the elements in a vector.

=cut

sub mean {
	shift->mean;
}

=pod

=head2 var

  my $variance = var($v);

The C<var> command returns the variance of the elements in a vector.

=cut

sub var {
	shift->var;
}

=pod

=head2 log

  my $zero = log( c(1) );

The C<log> command returns a vector where each element is the natural log
of the matching element in the input vector.

=cut

sub log {
	shift->log;
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=RLike>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2012 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
