package WiX3::XML::Environment;

####################################################################
# WiX3::XML::Environment - Object that represents an <Environment> tag.
#
# Copyright 2009 Curtis Jewell
#
# License is the same as perl. See Wix3.pm for details.
#
#<<<
use 5.008001;
use Moose;
use vars                 qw( $VERSION            );
use Params::Util         qw( _IDENTIFIER _STRING );
use WiX3::Types          qw( YesNoType           );
use MooseX::Types::Moose qw( Str );
use version; $VERSION = version->new('0.004')->numify;
#>>>

# http://wix.sourceforge.net/manual-wix3/wix_xsd_environment.htm

with 'WiX3::XML::Role::Tag';

# No child tags allowed.

#####################################################################
# Accessors:
#   see new.

has _id => (
	is => 'ro',
	isa => Str,
	reader => '_get_id',
	init_arg => 'id',
	required => 1,
);

has _name => (
	is => 'ro',
	isa => Str,
	reader => '_get_name',
	init_arg => 'name',
	required => 1,
);

has _value => (
	is => 'ro',
	isa => Str,
	reader => '_get_value',
	init_arg => 'value',
);

# TODO: These two are enums. Define types accordingly.
# Note: see http://wix.sourceforge.net/manual-wix3/wix_xsd_environment.htm for valid values.

has _action => (
	is => 'ro',
	isa => Str,
	reader => '_get_value',
	init_arg => 'value',
	default => 'set',
);

has _part => (
	is => 'ro',
	isa => Str,
	reader => '_get_part',
	init_arg => 'part',
	default => 'all',
);

has _permanent => (
	is => 'ro',
	isa => YesNoType,
	reader => '_get_permanent',
	init_arg => 'permanent',
	default => 'all',
);

has _system => (
	is => 'ro',
	isa => YesNoType,
	reader => '_get_system',
	init_arg => 'system',
	default => 'yes',
);

has _separator => (
	is => 'ro',
	isa => Str,
	reader => '_get_separator',
	init_arg => 'separator',
#	default => ';',   WiX defaults to this if not included
);

#####################################################################
# Main Methods

########################################
# as_string
# Parameters:
#   None.
# Returns:
#   String containing <Environment> tag defined by this object.

sub as_string {
	my $self      = shift;

	my $id = 'E_' . $self->get_id();

	# Print tag.
	my $answer;
	$answer	 = '< Environment';
	$answer .= $self->print_attribute('Id',        $id);
	$answer .= $self->print_attribute('Name',      $self->_get_name());
	$answer .= $self->print_attribute('Value',     $self->_get_value());
	$answer .= $self->print_attribute('System',    $self->_get_system());
	$answer .= $self->print_attribute('Permanent', $self->_get_permanent());
	$answer .= $self->print_attribute('Action',    $self->_get_action());
	$answer .= $self->print_attribute('Part',      $self->_get_part());
	$answer .= $self->print_attribute('Separator', $self->_get_separator());
	$answer .= " />\n";

	return $answer;
} ## end sub as_string

sub get_namespace {
	return q{xmlns='http://schemas.microsoft.com/wix/2006/wi'};
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
