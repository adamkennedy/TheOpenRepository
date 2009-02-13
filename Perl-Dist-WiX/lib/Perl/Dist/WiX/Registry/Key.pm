package Perl::Dist::WiX::Registry::Key;

#####################################################################
# Perl::Dist::WiX::Registry::Key - Class for <RegistryKey> tag.
#
# Copyright 2009 Curtis Jewell
#
# License is the same as perl. See Wix.pm for details.
#
#<<<
use     5.006;
use     strict;
use     warnings;
use     Carp               qw( croak               );
use     Params::Util       qw( _IDENTIFIER _STRING );
require Perl::Dist::WiX::Registry::Entry;

use vars qw( $VERSION );
use version; $VERSION = qv('0.13_02');
use base 'Perl::Dist::WiX::Base::Component';
#>>>
#####################################################################
# Accessors:
#   root: Returns the root parameter passed in to new.
#     Valid contents are 'HKLM' and 'HKCU'
#   key: Returns the key parameter passed in to new.
# See http://wix.sourceforge.net/manual-wix3/wix_xsd_registrykey.htm

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
    my $self = shift->SUPER::new( @_ );

    # Apply defaults
    unless ( defined $self->root ) {
        $self->{root} = 'HKLM';
    }
    unless ( defined $self->guid ) {
        $self->create_guid_from_id;
    }

    # Check params
    unless ( _IDENTIFIER( $self->root ) ) {
        croak( 'Missing or invalid root param' );
    }
    unless ( _STRING( $self->key ) ) {
        croak( 'Missing or invalid subkey param' );
    }
    unless ( _STRING( $self->id ) ) {
        croak( 'Missing or invalid id param' );
    }

    return $self;
} ## end sub new

#####################################################################
# Main Methods

########################################
# add_registry_entry($name, $value, $action, $value_type)
# Parameters:
#   $name, $value, $action, $value_type: See Registry::Entry->entry.
# Returns:
#   Object being called. (chainable)

sub add_registry_entry {
    my ( $self, $name, $value, $action, $value_type ) = @_;

    # Parameters checked in Registry::Entry->new

    # Pass this on to the new entry.
    $self->add_entry(
        Perl::Dist::WiX::Registry::Entry->entry(
            $name, $value, $action, $value_type
        ) );

    return $self;
} ## end sub add_registry_entry

########################################
# is_key($root, $key)
# Parameters:
#   $root: Root to compare against.
#   $key: Key to compare against.
# Returns:
#   True if this is the object representing $root and $key.

sub is_key {
    my ( $self, $root, $key ) = @_;

    unless ( _IDENTIFIER( $self->root ) ) {
        croak( 'Missing or invalid root param' );
    }
    unless ( _STRING( $self->key ) ) {
        croak( 'Missing or invalid subkey param' );
    }

    return 0 if ( uc $key  ne uc $self->key );
    return 0 if ( uc $root ne uc $self->root );
    return 1;
} ## end sub is_key

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
    return q{} if ( scalar @{ $self->{entries} } == 0 );

    $self->{root} = uc $self->{root};

    my $answer = <<"END_OF_XML";
<Component Id='C_$self->{id}' Guid='$self->{guid}'>
  <RegistryKey Root='$self->{root}' Key='$self->{key}'>
END_OF_XML

    $answer .= $self->SUPER::as_string( 4 );

    $answer .= <<"END_OF_XML";
  </RegistryKey>
</Component>
END_OF_XML

    return $answer;
} ## end sub as_string

1;
