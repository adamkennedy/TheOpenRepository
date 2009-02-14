package Perl::Dist::WiX::Registry::Entry;

#####################################################################
# Perl::Dist::WiX::Base::Component - Base class for <RegistryValue> tag.
#
# Copyright 2009 Curtis Jewell
#
# License is the same as perl. See Wix.pm for details.
#
#<<<
use 5.006;
use strict;
use warnings;
use Readonly      qw( Readonly                     );
use Carp          qw( croak                        );
use Params::Util  qw( _IDENTIFIER _STRING          );
use vars          qw( $VERSION                     );
use base          qw( Perl::Dist::WiX::Base::Entry );

use version; $VERSION = qv('0.13_02');
#>>>

# Defining at this level so they do not need recreated every time.
Readonly my @action_options => qw( append prepend write );
Readonly my @type_options =>
  qw ( string integer binary expandable multiString );

#####################################################################
# Accessors:
#   none.

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

sub new {
	my $self = shift->SUPER::new(@_);

	# Apply defaults
	unless ( defined $self->{value_type} ) {
		$self->{value_type} = 'expandable';
	}

	# Check params
	unless ( _IDENTIFIER( $self->{action} ) ) {
		croak 'Missing or invalid action param';
	}
	unless ( $self->check_options( $self->{action}, @action_options ) ) {
		croak 'Invalid action param (must be append, prepend, or write)';
	}
	unless ( $self->check_options( $self->{action}, @type_options ) ) {
		croak 'Invalid value_type param (see WiX documentation for '
		  . 'RegistryValue/@Type)';
	}
	unless ( _IDENTIFIER( $self->{value_name} ) ) {
		croak 'Missing or invalid value_name param';
	}
	unless ( _STRING( $self->{value_data} ) ) {
		croak 'Missing or invalid value_data param';
	}

	return $self;
} ## end sub new

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
	my $self = shift;
#<<<
    return
        q{<RegistryValue}
      . q{ Action='}      . $self->{action}
      . q{' Type='}       . $self->{value_type}
      . q{' Name='}       . $self->{value_name}
      . q{' Value='}      . $self->{value_data} . q{' />};
#>>>
}

1;
