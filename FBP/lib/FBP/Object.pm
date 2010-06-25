package FBP::Object;

=pod

=head1 NAME

FBP::Object - Base class for all wxFormBuilder objects

=head1 METHODS

=cut

use Mouse;

our $VERSION = '0.05';

=pod

=head2 raw

The full wxFormBuilder XML data structure will contain a far larger breadth
of properties than are actually supported in the L<FBP> object model.

In other cases, the object model may normalise a property that some specific
consumer will wish to access in the original form.

The C<raw> method provides access to a C<HASH> containing the keys and values
of the C<property> tags in the original XML document.

=cut

has raw => (
	is  => 'ro',
	isa => 'Any',
);

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=FBP>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2009 - 2010 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
