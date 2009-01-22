package Perl::Dist::WiX::Files::Component;

#####################################################################
# Perl::Dist::WiX::Files::Component - Class for a <Component> tag that contains file(s).
#
# Copyright 2009 Curtis Jewell
#
# License is the same as perl. See Wix.pm for details.

use 5.006;
use strict;
use warnings;
use Carp            qw( croak         );
use Params::Util    qw( _STRING       );
use Data::UUID      qw( NameSpace_DNS );
require Perl::Dist::WiX::Base::Component;
require Perl::Dist::WiX::Files::Entry;
                    
use vars qw{$VERSION @ISA};
BEGIN {
    $VERSION = '0.11_06';
    @ISA = 'Perl::Dist::WiX::Base::Component';
}

#####################################################################
# Accessors:
#   filename: Returns the filename parameter passed in to new.

use Object::Tiny qw{
    filename
};

#####################################################################
# Constructor for Files::Component
#
# Parameters: [pairs]
#   filename: The name of the file that is being added
#   sitename: The name of the site that is hosting the download.
#   id: Id parameter to the <Component> tag (generated if not given)
#   guid: Id parameter to the <Component> tag (generated if not given)  

sub new {
    my $self = shift->SUPER::new(@_);

    # Check parameters.
    unless ( _STRING($self->filename) ) {
        croak("Missing or invalid filename param");
    }
    
    unless ( _STRING($self->sitename) ) {
        croak("Missing or invalid sitename param - cannot generate GUID without one");
    }

    # Create a GUID if required. 
    unless ( defined $self->guid ) {
        my $guidgen = Data::UUID->new();
        # Make our own namespace...
        my $uuid =  $guidgen->create_from_name(Data::UUID::NameSpace_DNS, $self->sitename);
        #... then use it to create a GUID out of the filename.
        $self->{guid} = uc $guidgen->create_from_name_str($uuid, $self->filename);
        $self->{id} = $self->{guid}; 
        $self->{id} =~ s{-}{_}g;
    }

    # Add the entry (Each component contains one entry.)
    $self->{entries}->[0] = new Perl::Dist::WiX::Files::Entry(
        sitename => $self->sitename,
        name     => $self->filename,
    );
    
    return $self;
}

#####################################################################
# Main Methods

########################################
# is_file($filename)
# Parameters:
#   $filename: Filename being searched for
# Returns: [boolean]
#   True if this is the object for this filename.

sub is_file() {
    my ($self, $filename) = @_;

    return ($self->filename eq $filename);
}

########################################
# get_component_array
# Parameters:
#   None
# Returns:
#   Id attached to this component.

sub get_component_array {
    my $self = shift;

    return "C_$self->{id}";    
}

########################################
# as_string
# Parameters:
#   None
# Returns:
#   String representation of <Component> tag represented by this object,
#   along with the <File> entry it contains.

sub as_string {
    my $self = shift;
    
    # Short-circuit.
    return q{} if (0 == scalar @{$self->{entries}}); 

    # Start accumulating XML.
    my $answer = <<"END_OF_XML";
<Component Id='C_$self->{id}' Guid='$self->{guid}'>
END_OF_XML
    $answer .= $self->SUPER::as_string(2);
    $answer .= <<'END_OF_XML';
</Component>
END_OF_XML
    
    return $answer;
}

1;

