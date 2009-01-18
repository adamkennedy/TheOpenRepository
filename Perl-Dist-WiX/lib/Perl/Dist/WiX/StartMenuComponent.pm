package Perl::Dist::WiX::StartMenuComponent;

# Startmenu components contain the entry, so there is no WiX::Entry sub class

use 5.006;
use strict;
use warnings;
use Carp                              qw{ croak               };
use Params::Util                      qw{ _IDENTIFIER _STRING };
use Data::UUID                        qw{ NameSpace_DNS       };
use Perl::Dist::WiX::Base::Component  qw{};

use vars qw{$VERSION @ISA};
BEGIN {
    $VERSION = '0.11_04';
    @ISA = 'Perl::Dist::WiX::Base::Component';
}

use Object::Tiny qw{
    sitename
    name
    description
    target
    working_dir
};

#####################################################################
# Constructors for StartMenuComponent

sub new {
    my $self = shift->SUPER::new(@_);
    
    unless ( defined $self->guid ) {
        unless ( _STRING($self->sitename) ) {
            croak("Missing or invalid sitename param - cannot generate GUID without one");
        }
        unless ( _IDENTIFIER($self->id) ) {
            croak("Missing or invalid id param - cannot generate GUID without one");
        }
        my $guidgen = Data::UUID->new();
        # Make our own namespace...
        my $uuid = $guidgen->create_from_name(Data::UUID::NameSpace_DNS, $self->sitename);
        #... then use it to create a GUID out of the filename.
        $self->{guid} = uc $guidgen->create_from_name_str($uuid, $self->id);
    }

    # Check params
    unless ( _STRING($self->name) ) {
        croak("Missing or invalid name param");
    }
    unless ( _STRING($self->description) ) {
        croak("Missing or invalid name param");
    }
    unless ( _STRING($self->target) ) {
        croak("Missing or invalid name param");
    }
    unless ( _STRING($self->working_dir) ) {
        croak("Missing or invalid name param");
    }

    return $self;
}


#####################################################################
# Main Methods

sub as_string {
    my $self = shift;
        
    my $answer = <<END_OF_XML;
<Component Id='C_S_$self->{id}' Guid='$self->{guid}'>
   <Shortcut Id="S_$self->{id}" 
             Name="$self->{name}"
             Description="$self->{description}"
             Target="$self->{target}"
             WorkingDirectory="$self->{working_dir}" />
</Component>
END_OF_XML
    
    return $answer;
}

1;