package FBP::Window;

=pod

=head1 NAME

FBP::Window - Base class for all graphical wxWindow objects

=cut

use Moose;

our $VERSION = '0.04';

extends 'FBP::Object';
with    'FBP::Children';

=pod

=head2 id

The C<id> method returns the numeric wxWidgets identifier for the window.

=cut

has id => (
	is  => 'ro',
	isa => 'Str',
);

=pod

=head2 name

The C<name> method returns the logical name of the object.

=cut

has name => (
	is  => 'ro',
	isa => 'Str',
);

=pod

=head2 label

The C<label> method returns the visual label for the object.

=cut

has label => (
	is  => 'ro',
	isa => 'Str',
);

=pod

=head2 enabled

The C<enabled> method indicates if the object is enabled or not.

=cut

has enabled => (
	is  => 'ro',
	isa => 'Bool',
);

has pos => (
	is  => 'ro',
	isa => 'Str',
);

has size => (
	is  => 'ro',
	isa => 'Str',
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
