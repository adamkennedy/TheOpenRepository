package Identifier;

=pod

=head1 NAME

Identifier - Base class for globally-typed identifiers

=head1 DESCRIPTION

Many many systems have identifiers, unique values that are used to reliably
identify a single specific item from amoungst a group of items.

This module (and this namespace) provides ways of representing various
types of identifiers, so that they can be passed around inside of code and
you can know what they are.

In the C<Identifier> model, all identifier objects consist of three parts,
a type, an id, and a seperator.

Both the type and seperator are optional, and while not permitted to be
undefined, may be a null-string C<''>.

=head1 METHODS

=cut

use 5.005;
use strict;

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}

=pod

=head2 new

The C<new> method will vary to a degree for each L<Identifier> sub-class,
but will generally take some arbitrary set of parameters, and create
a validating object for the identifier.

Returns a new L<Identifier> (sub-class) object, or throws an exception
on error.

=cut

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;
	$self;
}

=pod

=head2 type

The C<type> accessor returns the type of the identifier.

Most of the time this will be a string, but in some cases like L<URI>-based
identifiers, it could be a L<URI> object, or some other form of object.

If the identifier is type-less, returns a null string.

=cut

sub type {
	my $class = ref $_[0] || $_[0];
	die "Identifier class $class does not implement method 'type'";
}

=pod

=head2 seperator

The C<seperator> accessor returns the seperator for the identifier.

This value is primarily used internally, and in most circumstances you
should never need to know this value, but access to it is included for
completeness.

=cut

sub seperator {
	my $class = ref $_[0] || $_[0];
	die "Identifier class $class does not implement method 'seperator'";
}

=pod

=head2 id

The C<id> accessor returns the varying part of the full identifier.

Most often, this will be an integer, or a string, or some other basic
character sequence. But the specific type of this value will be different
for different subclasses.

=cut

sub id {
	$_[0]->{id};
}

=pod

=head2 as_string

The C<as_string> method returns the full serialized string form of the
identifier.

=cut

sub as_string {
	$_[0]->type . $_[0]->seperator . $_[0]->id;
}

=pod

=head2 from_string

  my $id = My::Identifier->from_string( $string );

The C<from_string> method is parser that takes the string form of an
identifier, and parses it back into the object form.

Returns a new object, or throws an exception (dies) on error.

=cut

sub from_string {
	my $class = shift;
	die "Identifier class $class does not implement method 'from_string'";
}

1;

=pod

=head1 SUPPORT

Bugs should be always be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Identifier>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHORS

Adam Kennedy E<lt>cpan@ali.asE<gt>

=head1 SEE ALSO

L<http://ali.as/>, L<Data::GUID>

=head1 COPYRIGHT

Copyright (c) 2006 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
