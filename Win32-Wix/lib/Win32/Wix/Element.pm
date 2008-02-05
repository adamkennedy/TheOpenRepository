package Win32::Wix::Element;

=pod

=head1 NAME

Win32::Wix::Element - The abstract Element class, a base for all XML objects

=head1 INHERITANCE

  Win32::Wix::Element is the root of the XML class tree

=head1 DESCRIPTION

The abstract C<Win32::Wix::Element> serves as a base class for all XML
entities.

It describes a basic set of methods to provide a common interface
and implements basic versions of those methods.

=head1 METHODS

=cut

use strict;
use Scalar::Util 'refaddr';
use Params::Util qw{ _INSTANCE _ARRAY };
use Win32::Wix::Node ();
use Clone            ();
use List::MoreUtils  ();
use overload 'bool' => sub () { 1 },
             '=='   => '__equals',
             '!='   => '__nequals';

use vars qw{$VERSION %_PARENT};
BEGIN {
	$VERSION = '0.01';

	# Master Child -> Parent index
	%_PARENT = ();
}





#####################################################################
# General Properties

=pod

=head2 class

The C<class> method is provided as a convenience, and really does nothing
more than returning C<ref($self)>. However, some people have found that
they appreciate the laziness of C<$Foo-E<gt>class eq 'whatever'>, so I
have caved to popular demand and included it.

Returns the class of the Element as a string

=cut

sub class { ref($_[0]) }





#####################################################################
# Naigation Methods

=pod

=head2 parent

Elements themselves are not intended to contain other Elements, that is
left to the L<Win32::Wix::Node> abstract class, a subclass of C<Win32::Wix::Element>.
However, all Elements can be contained B<within> a parent Node.

If an Element is within a parent Node, the C<parent> method returns the
Node.

=cut

sub parent { $_PARENT{refaddr $_[0]} }

=pod

=head2 top

For a C<Win32::Wix::Element> that is contained within a XML tree, the C<top> method
will return the top-level Node in the tree. Most of the time this should be
a L<Win32::Wix::Document> object, unless a tree fragment is being built anonymously.

Returns the top-most XML object, which may be the same Element, if it is
not within any parent XML object.

=cut

sub top {
	my $cursor = shift;
	while ( my $parent = $_PARENT{refaddr $cursor} ) {
		$cursor = $parent;
	}
	$cursor;
}

=pod

For an Element that is contained within a L<Win32::Wix::Document> object,
the C<document> method will return the top-level Document for the Element.

Returns the L<Win32::Wix::Document> for this Element, or false if the Element is not
contained within a Document.

=cut

sub document {
	my $top = shift->top;
	_INSTANCE($top, 'Win32::Wix::Document') and $top;
}

=pod

=head2 next_sibling

All L<Win32::Wix::Node> objects (specifically, our parent Node) contain a
number of C<Win32::Wix::Element> objects. The C<next_sibling> method returns
the C<Win32::Wix::Element> immediately after the current one, or false if
there is no next sibling.

=cut

sub next_sibling {
	my $self     = shift;
	my $parent   = $_PARENT{refaddr $self} or return '';
	my $key      = refaddr $self;
	my $elements = $parent->{children};
	my $position = List::MoreUtils::firstidx {
		refaddr $_ == $key
		} @$elements;
	$elements->[$position + 1] || '';
}

=pod

=head2 previous_sibling

All L<Win32::Wix::Node> objects (specifically, our parent Node) contain a number of
C<Win32::Wix::Element> objects. The C<previous_sibling> method returns the Element
immediately before the current one, or false if there is no 'previous'
C<Win32::Wix::Element> object.

=cut

sub previous_sibling {
	my $self     = shift;
	my $parent   = $_PARENT{refaddr $self} or return '';
	my $key      = refaddr $self;
	my $elements = $parent->{children};
	my $position = List::MoreUtils::firstidx {
		refaddr $_ == $key
		} @$elements;
	$position and $elements->[$position - 1] or '';
}





#####################################################################
# Manipulation

=pod

=head2 clone

As per the L<Clone> module, the C<clone> method makes a perfect copy of
an Element object. In the generic case, the implementation is done using
the L<Clone> module's mechanism itself. In higher-order cases, such as for
Nodes, there is more work involved to keep the parent-child links intact.

=cut

sub clone {
	Clone::clone(shift);
}

=pod

=head2 insert_before @Elements

The C<insert_before> method allows you to insert lexical perl content, in
the form of C<Win32::Wix::Element> objects, before the calling C<Element>. You
need to be very careful when modifying perl code, as it's easy to break
things.

In its initial incarnation, this method allows you to insert a single
Element, and will perform some basic checking to prevent you inserting
something that would be structurally wrong (in XML terms).

In future, this method may be enhanced to allow the insertion of multiple
Elements, inline-parsed code strings or L<Win32::Wix::Document::Fragment> objects.

Returns true if the Element was inserted, false if it can not be inserted,
or C<undef> if you do not provide a L<Win32::Wix::Element> object as a parameter.

=cut

sub __insert_before {
	my $self = shift;
	$self->parent->__insert_before_child( $self, @_ );
}

=pod

=head2 insert_after @Elements

The C<insert_after> method allows you to insert lexical perl content, in
the form of C<Win32::Wix::Element> objects, after the calling C<Element>. You need
to be very careful when modifying perl code, as it's easy to break things.

In its initial incarnation, this method allows you to insert a single
Element, and will perform some basic checking to prevent you inserting
something that would be structurally wrong (in XML terms).

In future, this method may be enhanced to allow the insertion of multiple
Elements, inline-parsed code strings or L<Win32::Wix::Document::Fragment> objects.

Returns true if the Element was inserted, false if it can not be inserted,
or C<undef> if you do not provide a L<Win32::Wix::Element> object as a parameter.

=cut

sub __insert_after {
	my $self = shift;
	$self->parent->__insert_after_child( $self, @_ );
}

=pod

=head2 remove

For a given C<Win32::Wix::Element>, the C<remove> method will remove it from its
parent B<intact>, along with all of its children.

Returns the C<Element> itself as a convenience, or C<undef> if an error
occurs while trying to remove the C<Element>.

=cut

sub remove {
	my $self   = shift;
	my $parent = $self->parent or return $self;
	$parent->remove_child( $self );
}

=pod

=head2 delete

For a given C<Win32::Wix::Element>, the C<remove> method will remove it from its
parent, immediately deleting the C<Element> and all of its children (if it
has any).

Returns true if the C<Element> was successfully deleted, or C<undef> if
an error occurs while trying to remove the C<Element>.

=cut

sub delete {
	$_[0]->remove or return undef;
	$_[0]->DESTROY;
	1;
}




#####################################################################
# XML Compatibility Methods

sub _xml_name {
	my $class = ref $_[0] || $_[0];
	my $name  = lc join( '_', split /::/, $class );
	substr($name, 4);
}

sub _xml_attr {
	return {};
}

sub _xml_content {
	defined $_[0]->{content} ? $_[0]->{content} : '';
}





#####################################################################
# Internals

# Being DESTROYed in this manner, rather than by an explicit
# ->delete means our reference count has probably fallen to zero.
# Therefore we don't need to remove ourselves from our parent,
# just the index ( just in case ).
### XS -> Win32::Wix/XS.xs:_Win32::Wix_Element__DESTROY 0.900+
sub DESTROY { delete $_PARENT{refaddr $_[0]} }

# Operator overloads
sub __equals  { ref $_[1] and refaddr($_[0]) == refaddr($_[1]) }
sub __nequals { !__equals(@_) }

1;

=pod

=head1 TO DO

It would be nice if C<location> could be used in an ad-hoc manner. That is,
if called on an Element within a Document that has not been indexed, it will
do a one-off calculation to find the location. It might be very painful if
someone started using it a lot, without remembering to index the document,
but it would be handy for things that are only likely to use it once, such
as error handlers.

=head1 SUPPORT

See the L<support section|Win32::Wix/SUPPORT> in the main module.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2008 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
