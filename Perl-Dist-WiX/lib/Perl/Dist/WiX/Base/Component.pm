package Perl::Dist::WiX::Base::Component;

#####################################################################
# Perl::Dist::WiX::Base::Component - Base class for <Component> tag.
#
# Copyright 2009 Curtis Jewell
#
# License is the same as perl. See Wix.pm for details.
#
# WARNING: Class not meant to be created directly.
# Use as virtual base class and for "isa" tests only.
#
# $Rev$ $Date$ $Author$
# $URL$
#<<<
use     5.006;
use     strict;
use     warnings;
use     Carp              qw( croak                        );
use     Params::Util      qw( _CLASSISA _STRING _NONNEGINT );
use     Data::UUID        qw( NameSpace_DNS                );
require Perl::Dist::WiX::Misc;

use vars qw( $VERSION @ISA );
BEGIN {
    $VERSION = '0.13_01';
    @ISA = 'Perl::Dist::WiX::Misc';
}
#>>>
#####################################################################
# Accessors:
#   id: Returns the id parameter passed in to new.
#   guid: Returns the guid generated by new.
#   sitename: Returns the sitename parameter passed in to new.

use Object::Tiny qw{
  id
  guid
  sitename
};

#####################################################################
# Constructors for Base::Component
#
# Parameters: [pairs]
#   sitename: The name of the site that is hosting the download.
#   id: Id parameter to the <Component> tag
#   guid: Id parameter to the <Component> tag (generated if not given)

sub new {
    my ( $class, %params ) = @_;

    my $self = $class->SUPER::new( %params );

    $self->{entries} = [];

    return $self;
}

#####################################################################
# Main Methods

########################################
# add_entry($entry)
# Parameters:
#   $entry: Entry object being added. Must be a subclass of
#   Perl::Dist::WiX::Base::Entry
# Returns:
#   Object being called. (chainable)

sub add_entry {
    my ( $self, $entry ) = @_;

    if (
        not defined _CLASSISA( ref $entry, 'Perl::Dist::WiX::Base::Entry' )
      )
    {
        croak 'Not adding a valid component';
    }

  # getting the number of items in the array referred to by $self->{entries}
    my $i = scalar @{ $self->{entries} };

    $self->{entries}->[$i] = $entry;

    return $self;
} ## end sub add_entry

########################################
# create_guid_from_id
# Parameters:
#   None
# Action:
#   Creates a GUID from the sitename and id object variables and stores it
#   in the object.
# Returns:
#   Object being called. (chainable)

sub create_guid_from_id {
    my $self = shift;

    # Check parameters.
    unless ( _STRING( $self->sitename ) ) {
        croak(
"Missing or invalid sitename param - cannot generate GUID without one"
        );
    }
    unless ( _STRING( $self->id ) ) {
        croak(
            "Missing or invalid id param - cannot generate GUID without one"
        );
    }

    # Make our own namespace...
    my $guidgen = Data::UUID->new();
    my $uuid =
      $guidgen->create_from_name( Data::UUID::NameSpace_DNS,
        $self->sitename );

    #... then use it to create a GUID out of the ID.
    $self->{guid} = uc $guidgen->create_from_name_str( $uuid, $self->id );

    return $self;
} ## end sub create_guid_from_id

########################################
# as_string($spaces)
# Parameters:
#   $spaces: Number of spaces to indent string returned.
# Returns:
#   String representation of entries contained by this object.

sub as_string {
    my ( $self, $spaces ) = @_;
    my $string;
    my $s;

    # Short-circuit
    return q{} if ( scalar @{ $self->{entries} } == 0 );

    # Check parameters.
    unless ( defined _NONNEGINT( $spaces ) ) {
        croak
'Calling as_spaces improperly (most likely, not calling derived method)';
    }

    # Stringify each entry and indent it.
    my $count = scalar @{ $self->{entries} };
    foreach my $i ( 0 .. $count - 1 ) {
        $s = $self->{entries}->[$i]->as_string;
        $string .= $self->indent( $spaces, $s );
        $string .= "\n";
    }

    return $string;
} ## end sub as_string

1;
