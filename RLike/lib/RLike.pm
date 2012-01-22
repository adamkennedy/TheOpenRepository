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

=head1 FUNCTIONS

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
our @EXPORT  = qw{ c };

=pod

=head2 c

The C<c> function 

=cut

sub c {
	return undef unless @_;
	RLike::Vector->new(
		map {
			Params::Util::_INSTANCE($_, 'RLike::Vector') ? @$_ : $_
		} @_
	);
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
