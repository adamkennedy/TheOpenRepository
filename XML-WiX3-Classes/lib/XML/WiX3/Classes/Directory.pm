package XML::WiX3::Classes::Directory;

#<<<
use 5.006;
use Moose;
use vars              qw( $VERSION );
# use Params::Util      qw( _STRING  );

use version; $VERSION = version->new('0.003')->numify;
#>>>

with 'XML::WiX3::Classes::Role::Tag';
## Allows Component, Directory, Merge, and SymbolPath as children.

with 'XML::WiX3::Classes::Role::GeneratesGUID';

#####################################################################
# Accessors:
#   None.

has id => (
	is => 'ro',
	isa => 'Str',
	getter => 'get_id',
	default => undef,
);

# Path helps us in path searching.
has path => (
	is => 'ro',
	isa => 'Str',
	getter => 'get_path',
);

has noprefix => (
	is => 'ro',
	isa => 'Str',
	getter => '_get_noprefix',
	default => undef,
);

has _diskid => (
	is => 'ro',
	isa => 'Int',
	getter => '_get_diskid',
	default => undef,
);

has _filesource => (
	is => 'ro',
	isa => 'Str',
	getter => '_get_filesource',
	default => undef,
);

has name => (
	is => 'ro',
	isa => 'Str', # LongFileNameType
	getter => 'get_name',
	default => undef,
);

has _sourcename => (
	is => 'ro',
	isa => 'Str', # LongFileNameType
	getter => '_get_sourcename',
	default => undef,
);

has _shortname => (
	is => 'ro',
	isa => 'Str', # ShortFileNameType
	getter => '_get_shortname',
	default => undef,
);

has _shortsourcename => (
	is => 'ro',
	isa => 'Str', # ShortFileNameType
	getter => '_get_shortsourcename',
	default => undef,
);

# Since we generate GUID's when none is included, 
# ComponentGuidGenerationSeed is not needed.

#####################################################################
# Constructor for CreateFolder
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
		XWC::Exception::Parameter::Odd->throw();
	}

	unless (exists $args{'id'}) {
		my $id = generate_guid($args{'name'});
		$id =~ s{-}{_}g; 
		$args{'id'} = $id;
	}
	
	unless (defined _IDENTIFIER($args{'id'})) {
		XWC::Exception::Parameter::Invalid->throw('id');
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
# Main Methods

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

XML::WiX3::Classes::CreateFolder - Exceptions used in XML::WiX3::Objects.

=head1 VERSION

This document describes XML::WiX3::Classes::Exceptions version 0.003

=head1 SYNOPSIS

    eval { new XML::WiX3::Classes::RegistryKey() };
	if ( my $e = XWC::Exception::Parameter->caught() ) {

		my $parameter = $e->parameter;
		die "Bad Parameter $e passed in.";
	
	}
  
=head1 DESCRIPTION

This module defines the exceptions used by XML::WiX3::Classes.  All 
exceptions used are L<Exception::Class> objects.

Note that uncaught exceptions will try to print out an understandable
error message, and if a high enough tracelevel is available, will print
out a stack trace, as well.

=head1 INTERFACE 

=head2 ::Parameter

Parameter exceptions will always print a stack trace.

=head3 $e->parameter()

The name of the parameter with the error.

=head3 $e->info()

Information about how the parameter was bad.

=head3 $e->where()

Information about what routine had the bad parameter.

=back

=for author to fill in:
    Write a separate section listing the public components of the modules
    interface. These normally consist of either subroutines that may be
    exported, or methods that may be called on objects belonging to the
    classes provided by the module.


=head1 DIAGNOSTICS

This module provides the error diagnostics for the XML::WiX3::Objects 
distribution.  It has no diagnostics of its own.

=head1 CONFIGURATION AND ENVIRONMENT
  
XML::WiX3::Classes::Exceptions requires no configuration files or environment variables.

=head1 DEPENDENCIES

L<Exception::Class> version 1.22 or later.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-xml-wix3-classes@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Curtis Jewell  C<< <csjewell@cpan.org> >>

=head1 SEE ALSO

L<Exception::Class>

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

