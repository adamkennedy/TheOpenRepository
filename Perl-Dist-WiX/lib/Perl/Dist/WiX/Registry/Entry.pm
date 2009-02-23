package Perl::Dist::WiX::Registry::Entry;

#####################################################################
# Perl::Dist::WiX::Registry::Entry - Base class for <RegistryValue> tag.
#
# Copyright 2009 Curtis Jewell
#
# License is the same as perl. See Wix.pm for details.
#
#<<<
use 5.006;
use strict;
use warnings;
use vars              qw( $VERSION            );
use Object::InsideOut qw(
    Perl::Dist::WiX::Base::Entry
    Storable
);
use Readonly          qw( Readonly            );
use Params::Util      qw( _IDENTIFIER _STRING );

use version; $VERSION = qv('0.13_04');
#>>>

# Defining at this level so they do not need recreated every time.
Readonly my @ACTION_OPTIONS => qw( append prepend write );
Readonly my @TYPE_OPTIONS =>
  qw ( string integer binary expandable multiString );

#####################################################################
# Accessors:

my @action : Field : Arg(Name => 'action', Required => 1);
my @name : Field : Arg(Name => 'value_name', Required => 1);
my @type : Field : Arg(Name => 'value_type');
my @data : Field : Arg(Name => 'value_data', Required => 1);

#####################################################################
# Constructors for Registry::Entry
#
# Parameters: [pairs]
#   action:     Action attribute to <RegistryValue>.
#   value_type: Type attribute to <RegistryValue>.
#   value_name: Name attribute to <RegistryValue>.
#   value_data: Value attribute to <RegistryValue>.
#
# See http://wix.sourceforge.net/manual-wix3/wix_xsd_registryvalue.htm

sub _pre_init : Init {
	my ( $self, $args ) = @_;

	# Apply defaults
	unless ( defined $args->value_type ) {
		$args->{value_type} = 'expandable';
	}

	return;
}

sub _init : Init {
	my $self      = shift;
	my $object_id = ${$self};


	# Check params
	unless ( _IDENTIFIER( $action[$object_id] ) ) {
		PDWiX->throw('Invalid action param');
	}
	unless ( $self->check_options( $action[$object_id], @ACTION_OPTIONS ) )
	{
		PDWiX->throw(
			'Invalid action param (must be append, prepend, or write)');
	}
	unless ( $self->check_options( $type[$object_id], @TYPE_OPTIONS ) ) {
		## no critic 'RequireInterpolationOfMetachars'
		PDWiX->throw( 'Invalid value_type param (see WiX '
			  . q{documentation for RegistryValue/@Type)} );
	}
	unless ( _IDENTIFIER( $name[$object_id] ) ) {
		PDWiX->throw('Invalid value_name param');
	}
	unless ( _STRING( $data[$object_id] ) ) {
		PDWiX->throw('Invalid value_data param');
	}

	return $self;
} ## end sub _init :

#####################################################################
# Main Methods

########################################
# entry($value_name, $value_data, $action, $value_type)
# Parameters:
#   See constructor for details.

# Shortcut constructor for an environment variable
sub entry {
	return $_[0]->new(
		value_name => $_[1],
		value_data => $_[2],
		action     => $_[3],
		value_type => $_[4] );
}

########################################
# as_string
# Parameters:
#    None
# Returns:
#   String representation of the <RegistryValue> tags represented
#   by this object.

sub as_string {
	my $self      = shift;
	my $object_id = ${$self};

#<<<
    return
        q{<RegistryValue}
      . q{ Action='}      . $action[$object_id]
      . q{' Type='}       . $type[$object_id]
      . q{' Name='}       . $name[$object_id]
      . q{' Value='}      . $data[$object_id] . q{' />};
#>>>
} ## end sub as_string

1;
