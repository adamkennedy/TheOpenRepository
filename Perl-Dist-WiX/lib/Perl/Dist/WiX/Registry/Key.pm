package Perl::Dist::WiX::Registry::Key;

#####################################################################
# Perl::Dist::WiX::Registry::Key - Class for <RegistryKey> tag.
#
# Copyright 2009 Curtis Jewell
#
# License is the same as perl. See Wix.pm for details.

use 5.006;
use strict;
use warnings;
use Carp               qw( croak               );
use Params::Util       qw( _IDENTIFIER _STRING );
require Perl::Dist::WiX::Base::Component;
require Perl::Dist::WiX::Registry::Entry;

use vars qw($VERSION @ISA);
BEGIN {
    $VERSION = '0.11_06';
    @ISA = 'Perl::Dist::WiX::Base::Component';
}

#####################################################################
# Accessors:
#   root: Returns the root parameter passed in to new.
#     Valid contents are 'HKLM' and 'HKCU'
#   key: Returns the key parameter passed in to new.

use Object::Tiny qw{
    root
    key
};

#####################################################################
# Constructor for Registry::Key
#
# Parameters: [pairs]
#   root: Returns the root parameter passed in to new.
#     Valid contents are 'HKLM' and 'HKCU'
#   key: The registry key to write to.
#   id, guid, sitename: see WiX::Base::Component

sub new {
    my $self = shift->SUPER::new(@_);

    # Apply defaults
    unless ( defined $self->root ) {
        $self->{root} = 'HKLM';
    }
    
    unless ( defined $self->guid ) {
        $self->create_guid_from_id;
    }

    # Check params
    unless ( _IDENTIFIER($self->root) ) {
        croak("Missing or invalid root param");
    }

    unless ( _STRING($self->key) ) {
        croak("Missing or invalid subkey param");
    }

    unless ( _STRING($self->id) ) {
        croak("Missing or invalid id param");
    }
    
    return $self;
}

#####################################################################
# Main Methods

########################################
# add_registry_entry($name, $value, $action, $value_type)
# Parameters:
#   $name, $value, $action, $value_type: See Registry::Entry->entry.
# Returns: 
#   Object being called. (chainable)

sub add_registry_entry {
    my ($self, $name, $value, $action, $value_type) = @_;  
    
    $self->add_entry( 
        Perl::Dist::WiX::Registry::Entry->entry($name, $value, $action, $value_type));
    
    return $self;  
}

########################################
# is_key($root, $key)
# Parameters:
#   $root: Root to compare against.
#   $key: Key to compare against.
# Returns: 
#   True if this is the object representing $root and $key.

sub is_key {
    my ($self, $root, $key) = @_;
    
    return 0 if (uc $key ne uc $self->key);
    return 0 if (uc $root ne uc $self->root);
    return 1;
}

########################################
# as_string
# Parameters:
#    None
# Returns:
#   String representation of the <Component> and <RegistryKey> tags
#   represented by this object, and the <RegistryValue> tags contained 
#   by this object.

sub as_string {
    my $self = shift;
    
    # Short-circuit.
    return q{} if (scalar @{$self->{entries}} == 0); 

    $self->{root} = uc $self->{root};
    
    my $answer = <<END_OF_XML;
<Component Id='C_$self->{id}' Guid='$self->{guid}'>
  <RegistryKey Root='$self->{root}' Key='$self->{key}'>
END_OF_XML
   
    $answer .= $self->SUPER::as_string(4);
    
    $answer .= <<END_OF_XML;
  </RegistryKey>
</Component>
END_OF_XML
    
    return $answer;
}

1;