package WiX3::XML::Icon;

use 5.008001;
use Moose;
use vars                 qw( $VERSION );
use Params::Util         qw( _STRING  );
use MooseX::Types::Moose qw( Str      );
use WiX3::Util::StrictConstructor;

use version; $VERSION = version->new('0.004')->numify;

# http://wix.sourceforge.net/manual-wix3/wix_xsd_icon.htm

with 'WiX3::XML::Role::Tag';

## Allows no child tags.

has id => (
	is       => 'ro',
	isa      => Str,
	reader   => 'get_id',
	required => 1,
);

has sourcefile => (
	is       => 'ro',
	isa      => Str,
	reader   => 'get_sourcefile',
	required => 1,
);

#####################################################################
# Methods to implement the Tag role.

sub as_string {
	my $self = shift;

	my $directory = $self->_get_directory();
	my $children  = $self->has_child_tags();

	if ($children) {
		my $child_string = $self->as_string_children();
		if ( defined $directory ) {
			return
qq{<CreateFolder Directory='$directory'>\n$child_string<CreateFolder />\n};
		} else {
			return qq{<CreateFolder>\n$child_string<CreateFolder />\n};
		}
	} else {
		if ( defined $directory ) {
			return qq{<CreateFolder Directory='$directory' />\n};
		} else {
			return qq{<CreateFolder />\n};
		}
	}

} ## end sub as_string

sub get_namespace {
	return q{xmlns='http://schemas.microsoft.com/wix/2006/wi'};
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

WiX3::XML::Icon - Defines a Icon tag.

=head1 VERSION

This document describes WiX3::XML::Icon version 0.004

=head1 SYNOPSIS

TODO
  
=head1 DESCRIPTION

TODO

=head1 INTERFACE 

=for author to fill in:
    Write a separate section listing the public components of the modules
    interface. These normally consist of either subroutines that may be
    exported, or methods that may be called on objects belonging to the
    classes provided by the module.


=head1 DIAGNOSTICS

TODO

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-wix3@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Curtis Jewell  C<< <csjewell@cpan.org> >>

=head1 SEE ALSO

L<http://wix.sourceforge.net/>

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

