package XML::WiX3::Classes::Role::Fragment;

#<<<
use 5.006;
use Moose::Role;
use vars              qw( $VERSION );

use version; $VERSION = version->new('0.003')->numify;
#>>>

with 'XML::WiX3::Classes::Role::Tag';

has id (
	is => ro,
	isa	=> 'Str',
	required => 1,
	getter => 'get_id',
);

#####################################################################
# Main Methods

# Append the id parameter to 'Fr_' to indicate a fragment.
sub BUILDARGS {
	my $class = shift;
	
	if ( @_ == 1 && ! ref $_[0] ) {
		return { id => 'Fr_' . $_[0] };
	} elsif ( @_ == 1 && 'HASH' eq ref $_[0] ) {
		if (exists $_[0]->{id}) {
			$_[0]->{id} = 'Fr_' . $_[0]->{'id'};
			return $class->SUPER::BUILDARGS(@_);
		} else {
			XWC::Exception::Parameter::Missing->throw('id');
		}
	} else {
		my %hash = { @_ };
		if (exists $hash{id}) {
			$hash{id} = 'Fr_' . $hash{'id'};
			return $class->SUPER::BUILDARGS(%hash);
		} else {
			XWC::Exception::Parameter::Missing->throw('id');
		}		
	}
}

no Moose::Role;
1;

__END__

=head1 NAME

XML::WiX3::Classes::Role::Fragment - Role that says that this tag is a Fragment.

=head1 VERSION

This document describes XML::WiX3::Classes::Role::Fragment version 0.003

=head1 SYNOPSIS

	# This is a role. Use XML::WiX3::Classes::Fragment instead.
  
=head1 DESCRIPTION

This module defines a role that specifies that this tag is a Fragment tag.
 
=head1 INTERFACE 

=head2 get_id

Gets the id of this fragment.

=head1 DIAGNOSTICS

There are no diagnostics for this role.  However

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-xml-wix3-classes@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Curtis Jewell  C<< <csjewell@cpan.org> >>

=head1 SEE ALSO

L<XML::WiX3::Classes::Fragment>

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

