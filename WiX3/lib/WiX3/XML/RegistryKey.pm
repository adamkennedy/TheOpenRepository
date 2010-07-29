package WiX3::XML::RegistryKey;

####################################################################
# WiX3::XML::RegistryKey - Object that represents an <RegistryKey> tag.
#
# Copyright 2010 Curtis Jewell, Alexandr Ciornii
#
# License is the same as perl. See WiX3.pm for details.
#
use 5.008001;

# Must be done before Moose, or it won't get picked up.
use metaclass (
	metaclass   => 'Moose::Meta::Class',
	error_class => 'WiX3::Util::Error',
);
use Moose;
use Params::Util qw( _IDENTIFIER _STRING );
use WiX3::Types qw( EnumRegistryRootType );
use MooseX::Types::Moose qw( Str Maybe Bool );
use WiX3::Util::StrictConstructor;

our $VERSION = '0.009100';
$VERSION =~ s/_//ms;

# http://wix.sourceforge.net/manual-wix3/wix_xsd_registrykey.htm

with 'WiX3::XML::Role::TagAllowsChildTags';

# No child tags allowed.

#####################################################################
# Accessors:
#   see new.

has id => (
	is       => 'ro',
	isa      => Str,
	reader   => 'get_id',
	required => 1,
);

has remove_on_uninstall => (
	is     => 'ro',
	isa    => Bool,
	reader => '_get_remove_on_uninstall',
	required => 1,
);

has root => (
	is      => 'ro',
	isa     => EnumRegistryRootType,
	reader  => '_get_root',
	required => 1,
);

has key => (
	is      => 'ro',
	isa     => Maybe [Str],
	reader  => '_get_key',
);

#####################################################################
# Main Methods

########################################
# as_string
# Parameters:
#   None.
# Returns:
#   String containing <RegistryKey> tag defined by this object.

sub as_string {
	my $self = shift;

	my $id = 'RK_' . $self->get_id();

	# Print tag.
	my $answer;
	$answer = '<RegistryKey';
	$answer .= $self->print_attribute( 'Id',     $id );
	$answer .= $self->print_attribute( 'Root',   $self->_get_root() );
	$answer .= $self->print_attribute( 'Key',  $self->_get_value() );
	$answer .= $self->print_attribute( 'System', $self->_get_system() );
	if ($self->_get_remove_on_uninstall) {
		$answer .=
		  $self->print_attribute( 'Action', 'createAndRemoveOnUninstall' );
	} else {
		$answer .=
		  $self->print_attribute( 'Action', 'create' );
	}
	die "Childs should be here - RegistryValue";
	$answer .= " />\n";

	return $answer;
} ## end sub as_string

sub get_namespace {
	return q{xmlns='http://schemas.microsoft.com/wix/2006/wi'};
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
