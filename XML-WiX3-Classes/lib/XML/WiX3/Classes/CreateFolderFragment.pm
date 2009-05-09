package XML::WiX3::Classes::CreateFolderFragment;

#<<<
use 5.006;
use Moose;
use vars              qw( $VERSION     );
use Params::Util      qw( _IDENTIFIER  );

use version; $VERSION = version->new('0.003')->numify;
#>>>

with 'XML::WiX3::Classes::Role::Fragment';

has _tag => (
	is => 'ro',
	isa => 'XML::WiX3::Classes::Fragment',
	reader => '_get_tag',
	handles => [qw(search_file check_duplicates get_directory_id)],
);

#####################################################################
# Constructor for CreateFolderFragment
#
# Parameters: [pairs]
#   id, directory: See Base::Fragment.

sub BUILDARGS {
	my $class = shift;
	my ($id, $directory_id);
	
	if ( @_ == 2 && ! ref $_[0] ) {
		$id = $_[0];
		$directory_id = $_[1];
	}
	elsif ( @_ == 1 && 'HASH' eq ref $_[0] ) {
		my %args = %{ $_[0] };
		$id = $args{'id'};
		$directory_id = $args{'directory_id'};		
	}
	elsif (@_ == 4) {
		my %args = { @_ };
		$id = $args{'id'};
		$directory_id = $args{'directory_id'};		
	} else {
		XWC::Exception::Parameter->throw('Improperly called');
	}
	
	unless (defined $id) {
		XWC::Exception::Parameter::Missing->throw('id');
	}
	
	unless (defined $directory_id) {
		XWC::Exception::Parameter::Missing->throw('directory_id');
	}

	unless (defined _IDENTIFIER($id)) {
		XWC::Exception::Parameter::Invalid->throw('id');
	}
	
	unless (defined _IDENTIFIER($directory_id)) {
		XWC::Exception::Parameter::Invalid->throw('directory_id');
	}

	my $tag1 = XML::WiX3::Classes::Fragment->new(id => "Create$id" );
	my $tag2 = XML::WiX3::Classes::DirectoryRef->new(id => $directory_id );
	my $tag3 = XML::WiX3::Classes::Component->new(id => "Create$id" );
	my $tag4 = XML::WiX3::Classes::CreateFolder->new();
	
	$tag3->add_tag($tag4);
	$tag2->add_tag($tag3);
	$tag1->add_tag($tag2);

	return { '_tag' => $tag1 };
}

sub BUILD {
	my $self = shift;

	my $directory_id = $self->get_directory_id();
	
	$self->trace_line( 2,
		'Creating directory creation entry for directory '
	  . "id $directory_id\n" );
	
	return;
}

sub as_string {
	my $self = shift;
	
	return $self->_get_tag()->as_string();
}

sub get_namespace {
	return q{xmlns='http://schemas.microsoft.com/wix/2006/wi'};
}

1;

__END__

=head1 NAME

XML::WiX3::Classes::CreateFolderFragment - "Shortcut Fragment" containing only a CreateFolder entry.

=head1 VERSION

This document describes XML::WiX3::Classes::CreateFolderFragment version 0.003

=head1 SYNOPSIS

	my $fragment1 = XML::WiX3::Classes::CreateFolderFragment->new(
		id => $id1,
		directory_id = $directory_id1,
	);

	my $fragment2 = XML::WiX3::Classes::CreateFolderFragment->new({
		id => $id2,
		directory_id = $directory_id2,
	});

	my $fragment3 = XML::WiX3::Classes::CreateFolderFragment->new(
		$id3, $directory_id3);
	
=head1 DESCRIPTION

This module defines a fragment that contains only a CreateFolder tag and 
the parent tags required to implement it.

=head1 INTERFACE 

All callable routines other than new() are provided by 
L<XML::WiX3::Classes::Fragment>, and are documented there.

=head2 new()

the new() routine has 2 parameters: The id for the fragment, specified as C<id>, and
the id of the directory fragment to create, specified as C<directory_id>.

Parameters can be passed positionally (first the id parameter, and then the 
directory_id parameter) or via hash or hashref, as shown in the L<SYNOPSIS|#SYNOPSIS>.

=head1 DIAGNOSTICS

This module throws XWC::Exception::Parameter,  
XWC::Exception::Parameter::Missing, and XWC::Exception::Parameter::Invalid 
objects, which are documented in L<XML::WiX3::Classes::Exceptions>.

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

