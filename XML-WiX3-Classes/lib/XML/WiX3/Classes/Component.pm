package XML::WiX3::Classes::Component;

#<<<
use 5.006;
use Moose;
use vars              qw( $VERSION );
use Params::Util      qw( _STRING  );

use version; $VERSION = version->new('0.003')->numify;
#>>>

with 'XML::WiX3::Classes::Role::Tag';
## Allows lots of children: Choice of elements AppId, Category, Class, 
## Condition, CopyFile, CreateFolder, Environment, Extension, File, IniFile, 
## Interface, IsolateComponent, ODBCDataSource, ODBCDriver, ODBCTranslator, 
## ProgId, Registry, RegistryKey, RegistryValue, RemoveFile, RemoveFolder, 
## RemoveRegistryKey, RemoveRegistryValue, ReserveCost, ServiceConfig, 
## ServiceConfigFailureActions, ServiceControl, ServiceInstall, Shortcut, 
## SymbolPath, TypeLib 

#####################################################################
# Accessors:
#   None.

has id => (
	is => 'ro',
	isa => 'Str',
	reader => 'get_id',
	required => 1,
);

has _complusflags => (
	is => 'ro',
	isa => 'Maybe[Int]',
	reader => '_get_complusflags',
	init_arg => 'complusflags',
	default => undef,
);

has _directory => (
	is => 'ro',
	isa => 'Maybe[Str]',
	reader => '_get_directory',
	init_arg => 'directory',
	default => undef,
);

has _diskid => (
	is => 'ro',
	isa => 'Maybe[Int]',
	reader => '_get_diskid',
	init_arg => 'diskid',
	default => undef,
);

has _feature => (
	is => 'ro',
	isa => 'Maybe[Str]',
	reader => '_get_feature',
	init_arg => 'feature',
	default => undef,
);

has _guid => (
	is => 'ro',
	isa => 'Str', # ComponentGuidType
	reader => '_get_directory',
	init_arg => 'directory',
	default => 'PUT-GUID-HERE',
);

has _keypath => (
	is => 'ro',
	isa => 'Maybe[Bool]', # YesNoType
	reader => '_get_keypath',
	init_arg => 'keypath',
	default => undef,
);

has _location => (
	is => 'ro',
	isa => 'Maybe[Str]', # Enum: 'local', 'source', 'network'
	reader => '_get_location',
	init_arg => 'location',
	default => undef,
);

has _neveroverwrite => (
	is => 'ro',
	isa => 'Maybe[Bool]', # YesNoType
	reader => '_get_neveroverwrite',
	init_arg => 'neveroverwrite',
	default => undef,
);

has _permanent => (
	is => 'ro',
	isa => 'Maybe[Bool]', # YesNoType
	reader => '_get_permanent',
	init_arg => 'permanent',
	default => undef,
);

has _shared => (
	is => 'ro',
	isa => 'Maybe[Bool]', # YesNoType
	reader => '_get_shared',
	init_arg => 'shared',
	default => undef,
);

has _shareddllrefcount => (
	is => 'ro',
	isa => 'Maybe[Bool]', # YesNoType
	reader => '_get_shareddllrefcount',
	init_arg => 'shareddllrefcount',
	default => undef,
);

has _transitive => (
	is => 'ro',
	isa => 'Maybe[Bool]', # YesNoType
	reader => '_get_transitive',
	init_arg => 'transitive',
	default => undef,
);
has _updatewhensuperceded => (
	is => 'ro',
	isa => 'Maybe[Bool]', # YesNoType
	reader => '_get_updatewhensuperceded',
	init_arg => 'updatewhensuperceded',
	default => undef,
);
has _win64 => (
	is => 'ro',
	isa => 'Maybe[Bool]', # YesNoType
	reader => '_get_win64',
	init_arg => 'win64',
	default => undef,
);

# ComponentGuidType must match the regular expression: '[{(]?[0-9A-Fa-f]{8}\-?[0-9A-Fa-f]{4}\-?[0-9A-Fa-f]{4}\-?[0-9A-Fa-f]{4}\-?[0-9A-Fa-f]{12}[})]?|PUT\-GUID\-(?:\d+\-)?HERE|([!$])(\(var|\(loc|\(wix)\.[_A-Za-z][0-9A-Za-z_.]*\)|\*|^$'. 

#####################################################################
# Constructor for CreateFolder
#
# Parameters: [pairs]
#   id, directory: See Base::Fragment.

#####################################################################
# Main Methods

sub as_string {
	my $self = shift;

	my $directory = $self->_get_directory();
	my $children  = $self->has_child_tags();

	if ($children) {
		my $child_string = $self->as_string_children();
		if (defined $directory) {
			return qq{<CreateFolder Directory='$directory'>\n$child_string<CreateFolder />\n};
		} else {
			return qq{<CreateFolder>\n$child_string<CreateFolder />\n};
		}
	} else {
		if (defined $directory) {
			return qq{<CreateFolder Directory='$directory'/>\n};
		} else {
			return qq{<CreateFolder />\n};
		}
	}

} ## end sub as_string

sub get_namespace {
	return q{xmlns='http://schemas.microsoft.com/wix/2006/wi'};
}

1;

__END__

=head1 NAME

XML::WiX3::Classes::Component - Exceptions used in XML::WiX3::Objects.

=head1 VERSION

This document describes XML::WiX3::Classes::Component version 0.003

=head1 SYNOPSIS

	my $component = new XML::WiX3::Classes::Component(
		id => 'MyComponent',
		
	);

  
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

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-xml-wix3-classes@rt.cpan.org>, or through the web interface at
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

