package XML::WiX3::Classes::Role::Tag;

#<<<
use     5.006;
use		Moose::Role;
use     Params::Util  qw( _STRING _NONNEGINT );
use     vars          qw( $VERSION );
use     MooseX::AttributeHelpers;
require XML::WiX3::Classes::Exceptions;

use version; $VERSION = version->new('0.003')->numify;
#>>>

#####################################################################
# Attributes

# A tag can contain other tags.
has child_tags (
	metaclass => 'Collection::Array',
	is => 'rw',
	isa => 'ArrayRef[XML::WiX3::Classes::Role::Tag]',
	init_arg => undef,
	default => sub { return []; },
	provides => {
	  'elements' => 'get_child_tags',
	  'push'     => 'add_child_tag',
	  'get'      => 'get_child_tag',
	  'empty'    => 'has_child_tags',
	  'count'    => 'count_child_tags',
	}
);

#####################################################################
# Methods

# Tags have to be able to be strings.
requires 'as_string';

# Tags have to return the namespace they're in.
requires 'get_namespace';

########################################
# indent($spaces, $string)
# Parameters:
#   $spaces_num: Number of spaces to indent $string.
#   $string: String to indent.
# Returns:
#   Indented $string.

sub indent {
	my ( $self, $spaces, $string ) = @_;

	# Check parameters.
	unless ( defined $string ) {
		XWC::Exception::Parameter::Missing->throw('string');
	}

	unless ( defined $spaces_num ) {
		XWC::Exception::Parameter::Missing->throw('spaces_num');
	}

	unless ( defined _STRING($string) ) {
		XWC::Exception::Parameter::Invalid->throw('string');
	}

	unless ( defined _NONNEGINT($spaces_num) ) {
		XWC::Exception::Parameter::Invalid->throw('spaces_num');
	}

	# Indent string.
	my $spaces = q{ } x $spaces_num;
	my $answer = $spaces . $string;
	chomp $answer;
#<<<
		$answer =~ s{\n}                   # match a newline 
					{\n$spaces}gxms;       # and add spaces after it.
										   # (i.e. the beginning of the line.)
#>>>
	return $answer;
} ## end sub indent

sub as_string_children {
	my $self = shift;

	my $string;
	my $count = $self->count_child_tags();

	if (0 == $count) {
		return q{};
	}
	
	foreach my $tag ($self->get_child_tags()) {
		$string .= $tag->as_string();
	}

	return $self->indent(2, $string);
}

sub get_namespaces {
	my $self = shift;
	
	my @namespaces = ( $self->get_namespace() );
	my $count = $self->count_child_tags();

	if (0 == $count) {
		return @namespaces;
	}
	
	foreach my $tag ($self->get_child_tags()) {
		push @namespaces, $tag->get_namespaces();
	}

	return uniq @namespaces;
}

sub get_component_array {
	my $self = shift;

	my @components;
	my $count = $self->count_child_tags();

	if (0 == $count) {
		return ();
	}

	foreach my $tag ($self->get_child_tags()) {
		if ($tag->meta()->does_role('XML::WiX3::Classes::Role::Component')) {
			push @components, $tag->get_component_id();
		} else {
			push @components, $tag->get_component_array();
		}
	}

	return @components;
}

__PACKAGE__->meta->make_immutable;
no Moose::Role;

1;

__END__

=head1 NAME

XML::WiX3::Classes::Role::Tag - Base role for XML tags.

=head1 VERSION

This document describes XML::WiX3::Classes::Role::Tag version 0.003

=head1 SYNOPSIS

    # use XML::WiX3::Classes;

=head1 DESCRIPTION

This is the base class for all Classes that represent XML tags.

=head1 INTERFACE 

=head2 as_string

	$string = $tag->as_string();

Returns a string of XML that contains the tag defined by this object and all child tags.

This routine is implemented by classes satisfying this role.

=head2 as_string_children

	$string = $tag->as_string_children();

This routine returns a string of XML that contains the tag defined by this 
object and all child tags, and is used by L<as_string>.

=head2 indent

	$string = $tag->indent(4, $string);

This routine indents the string passed in with the given number of spaces, 
and is used by L<as_string>.

=head2 get_namespace

	$string = $tag->get_namespace();

Returns the namespace the tag uses. If the tag is in the main WiX namespace, 
this routine returns C<q{xmlns='http://schemas.microsoft.com/wix/2006/wi'}>.

This routine is implemented by classes satisfying this role.

=head2 get_namespaces

	@array = $tag->get_namespaces();

Returns an list of all namespaces used by the tag and its children.

If this tag and all child tags are in the main WiX namespace, this routine 
returns a list with one element: undef.

This routine is used by Fragment::as_string.

=head2 get_component_array

	@component_array = $tag->get_component_array()

Returns a list of components contained in this tag.  If there are no 
L<XML::WiX3::Classes::Role::Component> children in this tag, an empty list
is returned.

=head1 DIAGNOSTICS

The C<indent> routine will throw XWC::Exception::Parameter::Missing and 
XWC::Exception::Parameter::Invalid objects, which are defined in
L<XML::WiX3::Classes::Exceptions>.

There are no other diagnostics for this role, however, other diagnostics may 
be used by classes implementing this role.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-xml-wix3-classes@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Curtis Jewell  C<< <csjewell@cpan.org> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009, Curtis Jewell C<< <csjewell@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
