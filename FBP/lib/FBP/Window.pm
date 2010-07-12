package FBP::Window;

=pod

=head1 NAME

FBP::Window - Base class for all graphical wxWindow objects

=cut

use Mouse;

our $VERSION = '0.11';

extends 'FBP::Object';
with    'FBP::Children';
with    'FBP::KeyEvent';
with    'FBP::MouseEvent';
with    'FBP::FocusEvent';

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

=pod

=head2 pos

The C<pos> method returns the position of the window.

=cut

has pos => (
	is  => 'ro',
	isa => 'Str',
);

=pod

=head2 size

The C<size> method returns the size of the window, if it has a specific
strict size.

=cut

has size => (
	is  => 'ro',
	isa => 'Str',
);

=pod

=head2 window_style

The C<window_style> method returns a set of Wx style flags that are common
to all window types.

=cut

has window_style => (
	is  => 'ro',
	isa => 'Str',
);

=pod

=head2 styles

The C<styles> method returns the merged set of all constructor style flags
for the object.

You should generally call this method if you are writing code generators,
rather than calling C<style> or C<window_style> methods specifically.

=cut

sub styles {
	my $self   = shift;
	my @styles = grep { length $_ } (
		$self->can('style') ? $self->style : (),
		$self->window_style,
	) or return '';
	return join '|', @styles;
}

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
