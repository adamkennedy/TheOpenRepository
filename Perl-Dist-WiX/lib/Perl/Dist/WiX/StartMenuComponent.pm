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
#
# $Rev$ $Date$ $Author$
# $URL$

use 5.006;
use strict;
use warnings;
use Carp            qw( croak               );
use Params::Util    qw( _IDENTIFIER _STRING );
use Data::UUID      qw( NameSpace_DNS       );
require Perl::Dist::WiX::Base::Component;
require Perl::Dist::WiX::Misc;

use vars qw( $VERSION @ISA );
BEGIN {
    $VERSION = '0.13_01';
    @ISA = qw(
        Perl::Dist::WiX::Base::Component
        Perl::Dist::WiX::Misc
    );
}

#####################################################################
# Accessors:
#   name, description, target, working_dir, menudir_id: Returns the 
#     parameter of the same name passed in to new.

use Object::Tiny qw{
    name
    description
    target
    working_dir
    menudir_id
    icon_id
};

#####################################################################
# Constructor for StartMenuComponent
#
# Parameters: [pairs]
#   id, guid: See Base::Component.
#   name: Name attribute to the <Shortcut> tag.
#   description: Description attribute to the <Shortcut> tag.
#   target: Target of the <Shortcut> tag.
#   working_dir: WorkingDirectory attribute of the <Shortcut> tag.
#   menudir_id: Directory attribute of the <CreateFolder> tag.
#
# See http://wix.sourceforge.net/manual-wix3/wix_xsd_shortcut.htm
# and http://wix.sourceforge.net/manual-wix3/wix_xsd_createfolder.htm

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
    unless ( _STRING($self->menudir_id) ) {
        croak("Missing or invalid menudir_id param");
    }
    unless ( _STRING($self->icon_id) ) {
        croak("Missing or invalid icon_id param");
    }

    my $target = $self->target;
    $self->trace_line(3, "Adding Icon for $target\n");
    
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
            Icon='I_$self->{icon_id}'
            WorkingDirectory='D_$self->{working_dir}' />
  <CreateFolder Directory="$self->{menudir_id}" />
</Component>
END_OF_XML
    
}

1;
