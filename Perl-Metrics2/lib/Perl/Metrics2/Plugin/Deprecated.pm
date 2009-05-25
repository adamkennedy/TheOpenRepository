package Perl::Metrics2::Plugin::Core;

=pod

=head1 NAME

Perl::Metrics2::Plugin::Core - The Core Perl Metrics Package

=head1 DESCRIPTION

This class provides a set of core metrics for Perl documents, based on
very simple code using only the core L<PPI> package.

=head1 METRICS

As with all L<Perl::Metrics::Plugin> packages, all metrics can be
referenced with the global identifier C<Perl::Metrics::Plugin::Core::metric>.

Metrics are listed as "datatype name".

=cut

use strict;
use bytes                  ();
use List::Util             ();
use Perl::Metrics2::Plugin ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '0.03';
	@ISA     = 'Perl::Metrics2::Plugin';
}

=pod

=head2 boolean array_first_element_index

The C<array_first_element_index> flag is true if the file uses the deprecated
C<$[> magic variable.

=cut

sub metric_array_first_element_index {
	$_[1]->find_any( sub {
		$_[1]->isa('PPI::Token::Magic')
		and
		$_[1]->content eq '$['
	} ) ? 1 : 0;
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Metrics2>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Perl::Metrics::Plugin>, L<Perl::Metrics>, L<PPI>

=head1 COPYRIGHT

Copyright 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
