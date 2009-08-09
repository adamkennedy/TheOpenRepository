package WiX3::XML::Component;

#<<<
use 5.008001;
use Moose;
use vars                  qw( $VERSION                    );
use Params::Util          qw( _STRING                     );
use WiX3::Types           qw( YesNoType ComponentGuidType );
use MooseX::Types::Moose  qw( Str Maybe Int               );

use version; $VERSION = version->new('0.004')->numify;
#>>>

with 'WiX3::XML::Role::Tag';
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
	isa => Str,
	reader => 'get_id',
	required => 1,
);

has _complusflags => (
	is => 'ro',
	isa => Maybe[Int],
	reader => '_get_complusflags',
	init_arg => 'complusflags',
	default => undef,
);

has _directory => (
	is => 'ro',
	isa => Maybe[Str],
	reader => '_get_directory',
	init_arg => 'directory',
	default => undef,
);

# DisableRegistryReflection requires Windows Installer 4.0

has _disableregistryreflection => (
	is => 'ro',
	isa => Maybe[YesNoType],
	reader => '_get_disableregistryreflection',
	init_arg => 'disableregistryreflection',
	default => undef,
);

has _diskid => (
	is => 'ro',
	isa => Maybe[Int],
	reader => '_get_diskid',
	init_arg => 'diskid',
	default => undef,
);

has _feature => (
	is => 'ro',
	isa => Maybe[Str],
	reader => '_get_feature',
	init_arg => 'feature',
	default => undef,
);

has _guid => (
	is => 'ro',
	isa => ComponentGuidType,
	reader => '_get_guid',
	init_arg => 'guid',
	default => 'PUT-GUID-HERE',
);

has _keypath => (
	is => 'ro',
	isa => Maybe[YesNoType],
	reader => '_get_keypath',
	init_arg => 'keypath',
	default => undef,
);

has _location => (
	is => 'ro',
	isa => Maybe[Str], # Enum: 'local', 'source', 'network'
	reader => '_get_location',
	init_arg => 'location',
	default => undef,
);

has _neveroverwrite => (
	is => 'ro',
	isa => Maybe[YesNoType],
	reader => '_get_neveroverwrite',
	init_arg => 'neveroverwrite',
	default => undef,
);

has _permanent => (
	is => 'ro',
	isa => Maybe[YesNoType],
	reader => '_get_permanent',
	init_arg => 'permanent',
	default => undef,
);

# Shared requires Windows Installer 4.5

has _shared => (
	is => 'ro',
	isa => Maybe[YesNoType],
	reader => '_get_shared',
	init_arg => 'shared',
	default => undef,
);

has _shareddllrefcount => (
	is => 'ro',
	isa => Maybe[YesNoType],
	reader => '_get_shareddllrefcount',
	init_arg => 'shareddllrefcount',
	default => undef,
);

has _transitive => (
	is => 'ro',
	isa => Maybe[YesNoType],
	reader => '_get_transitive',
	init_arg => 'transitive',
	default => undef,
);

# UninstallWhenSuperceded requires Windows Installer 4.5

has _uninstallwhensuperceded => (
	is => 'ro',
	isa => Maybe[YesNoType],
	reader => '_get_uninstallwhensuperceded',
	init_arg => 'uninstallwhensuperceded',
	default => undef,
);

has _win64 => (
	is => 'ro',
	isa => Maybe[YesNoType],
	reader => '_get_win64',
	init_arg => 'win64',
	default => undef,
);

#####################################################################
# Methods to implement the Tag role.

sub as_string {
	my $self = shift;

	my $children  = $self->has_child_tags();
	my $child_string = $self->as_string_children();
	my $id = 'C_' . $self->get_id();

	
	my $string;
	$string  = '<Component';
	
	my %attribute = ( 
		'Id'                        => $id,
		'ComPlusFlags'              => $self->_get_complusflags(),
		'Directory'                 => $self->_get_directory(),
		'DisableRegistryReflection' => $self->_get_disableregistryreflection(),
		'DiskId'                    => $self->_get_diskid(),
		'Feature'                   => $self->_get_feature(),
		'Guid'                      => $self->_get_guid(),
		'Keypath'                   => $self->_get_keypath(),
		'Location'                  => $self->_get_location(),
		'NeverOverwrite'            => $self->_get_neveroverwrite(),
		'Permanent'                 => $self->_get_permanent(),
		'Shared'                    => $self->_get_shared(),
		'SharedDllRefCount'         => $self->_get_shareddllrefcount(),
		'Transitive'                => $self->_get_transitive(),
		'UninstallWhenSuperceded'   => $self->_get_uninstallwhensuperceded(),
		'Win64'                     => $self->_get_win64()
	);
	
	my ($k, $v);
	
	while (($k, $v) = each %attribute) {	
		$string .= $self->print_attribute($k, $v);
	}
	
	$string .= " />\n";
	
	if ($children) {
		$string .= qq{>\n$child_string<Component />\n};
	} else {
		$string .= qq{ />\n};
	}
	
	return $string;
} ## end sub as_string

sub get_namespace {
	return q{xmlns='http://schemas.microsoft.com/wix/2006/wi'};
}

#####################################################################
# Other methods.

sub get_directory_id {
	my $self = shift;
	my $id = $self->get_id();
	
	if ($self->noprefix()) {
		return $id;
	} else {
		return "D_$id";
	}
}

1;

__END__

=head1 NAME

WiX3::XML::Component - Defines a Component tag.

=head1 VERSION

This document describes WiX3::XML::Component version 0.004

=head1 SYNOPSIS

	my $component = new XML::WiX3::Classes::Component(
		id => 'MyComponent',
		
	);

  
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

