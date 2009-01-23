package Perl::Dist::WiX::StartMenuComponent;

#####################################################################
# Perl::Dist::WiX::StartMenuComponent - A <Component> tag that contains a start menu <Shortcut>.
#
# Copyright 2009 Curtis Jewell
#
# License is the same as perl. See Wix.pm for details.
#
# WARNING: Class not meant to be created directly, except through 
# Perl::Dist::WiX::StartMenu.
#
# StartMenu components contain the entry, so there is no WiX::Entry sub class

use 5.006;
use strict;
use warnings;
use Carp                              qw{ croak               };
use Params::Util                      qw{ _IDENTIFIER _STRING };
use Data::UUID                        qw{ NameSpace_DNS       };
use Perl::Dist::WiX::Base::Component  qw{};

use vars qw{$VERSION @ISA};
BEGIN {
    $VERSION = '0.11_06';
    @ISA = 'Perl::Dist::WiX::Base::Component';
}

#####################################################################
# Accessors:
#   name, description, target, working_dir: Returns the parameter 
#     of the same name passed in to new.

use Object::Tiny qw{
    name
    description
    target
    working_dir
};

#####################################################################
# Constructor for StartMenuComponent
#
# Parameters: [pairs]
#   id, guid: See Base::Component.
#   name: Name attribute to the <Shortcut> tag.
#   description: Description attribute to the <Shortcut> tag.
#   target: Target of the <Shortcut> tag.
#   working_dir: WorkingDirectory target of the <Shortcut> tag.

sub new {
    my $self = shift->SUPER::new(@_);
    
    # Check parameters.
    unless ( defined $self->guid ) {
        $self->create_guid_from_id;
    }
    unless ( _STRING($self->name) ) {
        croak("Missing or invalid name param");
    }
    unless ( _STRING($self->description) ) {
        $self->{description} = $self->name;
    }
    unless ( _STRING($self->target) ) {
        croak("Missing or invalid target param");
    }
    unless ( _STRING($self->working_dir) ) {
        croak("Missing or invalid working_dir param");
    }

    return $self;
}

#####################################################################
# Main Methods

########################################
# as_string
# Parameters:
#   None.
# Returns:
#   String representation of the <Component> and <Shortcut> tags represented
#   by this object.

sub as_string {
    my $self = shift;
        
    return <<"END_OF_XML";
<Component Id='C_S_$self->{id}' Guid='$self->{guid}'>
   <Shortcut Id='S_$self->{id}' 
             Name='$self->{name}'
             Description='$self->{description}'
             Target='$self->{target}'
             WorkingDirectory='$self->{working_dir}' />
</Component>
END_OF_XML
    
}

1;
