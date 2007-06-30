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

=head2 new

The C<new> method will vary to a degree for each L<Identifier> sub-class,
but will generally take some arbitrary set of parameters, and create
a validating object for the identifier.



=cut

use 5.005;
use strict;

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;
	$self;
}

sub type {
	my $class = ref $_[0] || $_[0];
	die "Identifier class $class does not implement method 'type'";
}

sub seperator {
	my $class = ref $_[0] || $_[0];
	die "Identifier class $class does not implement method 'seperator'";
}

sub id {
	$_[0]->{id};
}

sub as_string {
	$_[0]->type . $_[0]->seperator . $_[0]->id;
}

1;

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
