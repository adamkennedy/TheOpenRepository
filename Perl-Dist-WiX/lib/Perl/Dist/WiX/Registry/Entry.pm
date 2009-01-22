package Perl::Dist::WiX::Registry::Entry;

#####################################################################
# Perl::Dist::WiX::Base::Component - Base class for <RegistryValue> tag.
#
# Copyright 2009 Curtis Jewell
#
# License is the same as perl. See Wix.pm for details.
#

use 5.006;
use strict;
use warnings;
use Carp              qw{ croak               };
use Params::Util      qw{ _IDENTIFIER _STRING };
require Perl::Dist::WiX::Base::Entry;

use vars qw{$VERSION @ISA};
BEGIN {
    $VERSION = '0.11_06';
    @ISA = 'Perl::Dist::WiX::Base::Entry';
}

#####################################################################
# Accessors:
#   action, value_type, value_name, value_data:
#     see constructor for information.

use Object::Tiny qw{
    action
    value_type
    value_name
    value_data
};

#####################################################################
# Constructors for Registry::Entry
#
# Parameters: [pairs]
#   action:     Action attribute to <RegistryKey>.
#   value_type: Type attribute to <RegistryKey>.
#   value_name: Name attribute to <RegistryKey>.
#   value_data: Value attribute to <RegistryKey>.

sub new {
    my $self = shift->SUPER::new(@_);

    # Apply defaults
    unless ( defined $self->value_type ) {
        $self->{value_type} = 'expandable';
    }

    # Check params
    unless ( _IDENTIFIER($self->action) ) {
        croak("Missing or invalid action param");
    }
    unless ( _IDENTIFIER($self->value_type) ) {
        croak("Invalid value_type param");
    }
    unless ( _IDENTIFIER($self->value_name) ) {
        croak("Missing or invalid value_name param");
    }
    unless ( _STRING($self->value_data) ) {
        croak("Missing or invalid value_data param");
    }

    return $self;
}

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
        value_type => $_[4]
    );
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

    return q{<RegistryValue} .
        q{ Action='}  . $self->action .
        q{' Type='}   . $self->value_type .
        q{' Name='}   . $self->value_name .
        q{' Value='}  . $self->value_data . q{' />}
    ;
}

1;