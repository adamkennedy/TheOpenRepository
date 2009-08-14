package WiX3::XML::Role::TagAllowsChildTags;

use 5.008001;
use Moose::Role;
use WiX3::Exceptions;
use WiX3::Types qw(IsTag);
use MooseX::AttributeHelpers;
use MooseX::Types::Moose qw(ArrayRef);

use version; our $VERSION = version->new('0.004')->numify;

with 'WiX3::XML::Role::Tag';

#####################################################################
# Attributes

# A tag can contain other tags.
has child_tags => (
	metaclass => 'Collection::Array',
	is        => 'rw',
	isa       => ArrayRef [IsTag],
	init_arg  => undef,
	default   => sub { return []; },
	provides  => {
		'elements' => 'get_child_tags',
		'push'     => 'add_child_tag',
		'get'      => 'get_child_tag',
		'empty'    => 'has_child_tags',
		'count'    => 'count_child_tags',
		'delete'   => 'delete_child_tag',
	},
);

# I think you could do method aliasing... with 'Role' => { alias => { 'add_child_tag' => '_add_child_tag' } }
# then implement your own child tag to do validation

#####################################################################
# Methods

sub as_string_children {
	my $self = shift;

	my $string;
	my $count = $self->count_child_tags();

	if ( 0 == $count ) {
		return q{};
	}

	foreach my $tag ( $self->get_child_tags() ) {
		$string .= $tag->as_string();
	}

	return $self->indent( 2, $string );
} ## end sub as_string_children

no Moose::Role;

1;

__END__

=head1 NAME

WiX3::XML::Role::TagAllowsChildTags - Base role for XML tags that have children.

=head1 VERSION

This document describes WiX3::XML::Role::TagAllowsChildTags version 0.003

=head1 SYNOPSIS

    # use WiX3;

=head1 DESCRIPTION

This is the base class for all WiX3 classes that represent XML tags.

=head1 INTERFACE 

=head2 as_string_children

	$string = $tag->as_string_children();

This routine returns a string of XML that contains the tag defined by this 
object and all child tags, and is used by L<as_string>.

=head1 DIAGNOSTICS

There are no diagnostics for this role, however, other diagnostics may 
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
