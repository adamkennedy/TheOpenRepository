package Perl::Dist::WiX::Base::Fragment;

#####################################################################
# Perl::Dist::WiX::Base::Fragment - Base class for <Fragment> tag.
#
# Copyright 2009 Curtis Jewell
#
# License is the same as perl. See Wix.pm for details.
#
# WARNING: Class not meant to be created directly.
# Use as virtual base class and for "isa" tests only.

use 5.006;
use strict;
use warnings;
use Carp                  qw( croak             );
use Params::Util          qw( _CLASSISA _STRING );
require Perl::Dist::WiX::Misc;

use vars qw($VERSION @ISA);
BEGIN {
    $VERSION = '0.11_06';
    @ISA = 'Perl::Dist::WiX::Misc';
}

#####################################################################
# Accessors:
#   id: Returns the id parameter passed in to new.
#   directory: Returns the directory parameter passed in to new.

use Object::Tiny qw{
    id
    directory
};

#####################################################################
# Constructor for Base::Fragment
#
# Parameters: [pairs]
#   id: Id parameter to the <Fragment> tag (required)
#   directory: Id parameter to the <DirectoryRef> tag  within this fragment. 

sub new {
    my $self = shift->SUPER::new(@_);
    
    unless ( defined $self->directory ) {
        $self->{directory} = 'TARGETDIR';
    }
    
    unless ( _STRING($self->id) ) {
        croak 'Missing or invalid id parameter';
    }
    
    $self->{components} = [];
    
    return $self;
}

#####################################################################
# Main Methods

########################################
# add_component($component)
# Parameters:
#   $component: Component object being added. Must be a subclass of
#   Perl::Dist::WiX::Base::Component
# Returns: 
#   Object being called. (chainable)


sub add_component {
    my ($self, $component) = @_;
    
    if (not defined _CLASSISA(ref $component, 'Perl::Dist::WiX::Base::Component')) {
        croak 'Not adding a valid component';
    }
    
    # Adding component to the list.
    my $i = scalar @{$self->{components}};
    $self->{components}->[$i] = $component;
    
    return $self;
}

########################################
# as_string
# Parameters:
#   None
# Returns:
#   String representation of <Fragment> and <DirectoryRef> tags represented 
#   by this object, along with the components it contains.

sub as_string {
    my ($self) = shift;
    my $string;
    my $s;
 
    # Short-circuit.
    return q{} if (0 == scalar @{$self->{components}}); 

    # Start with XML header and opening tags.
    $string = <<"END_OF_XML";
<?xml version='1.0' encoding='windows-1252'?>
<Wix xmlns='http://schemas.microsoft.com/wix/2006/wi'>
  <Fragment Id='Fr_$self->{id}'>
    <DirectoryRef Id='$self->{directory}'>
END_OF_XML

    # Stringify the components we contain.
    my $count = scalar @{$self->{components}};
    foreach my $i (0 .. $count - 1) {
        $s = $self->{components}->[$i]->as_string;
        chomp $s;
        $string .= $self->indent(6, $s);
        $string .= "\n";
    }
    
    # Finish up.
    $string .= <<'END_OF_XML';
    </DirectoryRef>
  </Fragment>
</Wix>
END_OF_XML

    return $string;
}

1;
