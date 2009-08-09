package XML::WiX3::Classes::Directory;

#<<<
use 5.006;
use Moose;
use vars              qw( $VERSION );
# use Params::Util      qw( _STRING  );
use MooseX::Types::Moose qw( Int Str  );


use version; $VERSION = version->new('0.004')->numify;
#>>>

with 'WiX3::XML::Role::TagAllowsChildTags';
## Allows Component, Directory, Merge, and SymbolPath as children.

with 'WiX3::XML::Role::GeneratesGUID';

#####################################################################
# Accessors:
#   None.

has id => (
	is => 'ro',
	isa => Str,
	reader => 'get_id',
	default => undef,
);

# Path helps us in path searching.
has path => (
	is => 'ro',
	isa => Str,
	reader => 'get_path',
);

has noprefix => (
	is => 'ro',
	isa => Str,
	reader => '_get_noprefix',
	default => undef,
);

has _diskid => (
	is => 'ro',
	isa => Int,
	reader => '_get_diskid',
	init_arg => 'diskid',
	default => undef,
);

has _filesource => (
	is => 'ro',
	isa => Str,
	reader => '_get_filesource',
	init_arg => 'filesource',
	default => undef,
);

has name => (
	is => 'ro',
	isa => Str, # LongFileNameType
	reader => 'get_name',
	default => undef,
);

has _sourcename => (
	is => 'ro',
	isa => Str, # LongFileNameType
	reader => '_get_sourcename',
	init_arg => 'sourcename',
	default => undef,
);

has _shortname => (
	is => 'ro',
	isa => Str, # ShortFileNameType
	reader => '_get_shortname',
	init_arg => 'shortname',
	default => undef,
);

has _shortsourcename => (
	is => 'ro',
	isa => Str, # ShortFileNameType
	reader => '_get_shortsourcename',
	init_arg => 'shortsourcename',
	default => undef,
);

# Since we generate GUID's when none is included, 
# ComponentGuidGenerationSeed is not needed.

#####################################################################
# Constructor for Directory
#

sub BUILDARGS {
	my $class = shift;
	my %args;
	
	if ( @_ == 1 && 'HASH' eq ref $_[0] ) {
		%args = %{ $_[0] };
	}
	elsif (@_ % 2 == 0) {
		%args = { @_ };
	} else {
		WiX3::Exception::Parameter::Odd->throw();
	}

	unless (exists $args{'id'}) {
		my $id = generate_guid($args{'path'});
		$id =~ s{-}{_}g; 
		$args{'id'} = $id;
	}
	
	unless (defined _IDENTIFIER($args{'id'})) {
		WiX3::Exception::Parameter::Invalid->throw('id');
	}
}

sub get_directory_id {
	my $self = shift;
	my $id = $self->get_id();
	
	if ($self->noprefix()) {
		return $id;
	} else {
		return "D_$id";
	}
}

#####################################################################
# Methods to implement the Tag role.

sub as_string {
	my $self = shift;

	my $children  = $self->has_children();
	my $tags;
	$tags  = $self->print_attribute('Id', $self->get_directory_id());
	$tags .= $self->print_attribute('Name', $self->get_name());
	$tags .= $self->print_attribute('ShortName', $self->_get_shortname());
	$tags .= $self->print_attribute('SourceName', $self->_get_sourcename());
	$tags .= $self->print_attribute('ShortSourceName', $self->_get_shortsourcename());
	$tags .= $self->print_attribute('DiskId', $self->_get_diskid());
	$tags .= $self->print_attribute('FileSource', $self->_get_filesource());
	
	if ($children) {
		my $child_string = $self->as_string_children();
		return qq{<Directory$tags>\n$child_string</Directory>\n};
	} else {
		return q{<Directory$tags />\n};
	}
} ## end sub as_string

sub get_namespace {
	return q{xmlns='http://schemas.microsoft.com/wix/2006/wi'};
}

1;

__END__

=head1 NAME

WiX3::XML::Directory - Class representing a Directory tag.

=head1 VERSION

This document describes WiX3::XML::Directory version 0.004

=head1 SYNOPSIS

    my $tag = WiX3::XML::Directory->new(
	  name => 'Test';
	  path => 'ProgramFilesDir\Test';
	);
  
=head1 DESCRIPTION

This class represents a Directory tag and takes most non-deprecated 
attributes that the tag has (ComponentGuidGenerationSeed is the exception)
as parameters.

If an C<id> parameter is not passed, one will be generated using the C<path> parameter.

All attributes are lowercased when passed as a parameter.

=head1 INTERFACE 

This class implementes all methods of the L<XML::WiX3::Classes::Role::Tag> role.

=head2 Other parameters to new

These parameters will not go into the XML output, although they may affect it.

=head3 path

This is a path that will be used when searching for this directory.

To easily implement this when using standard directories, just use the 
standard directory name as the root.

=head3 noprefix

The Id printed in the XML that this class generates will have a prefix of 
C<D_> unless this is set to true.

This is used for standard directories.

=head2 get_directory_id

Returns the ID of the directory as it will be printed out in the XML file.

=for author to fill in:
    Write a separate section listing the public components of the modules
    interface. These normally consist of either subroutines that may be
    exported, or methods that may be called on objects belonging to the
    classes provided by the module.

=head1 DIAGNOSTICS

This module throws an WiX3::Exception::Parameter::Odd object upon build if 
the parameter count is incorrect.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-wix3@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Curtis Jewell  C<< <csjewell@cpan.org> >>

=head1 SEE ALSO

L<http://wix.sourceforge.net/manual-wix3/wix_xsd_directory.htm>

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

