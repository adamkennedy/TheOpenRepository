package Perl::Dist::WiX::Files::Component;

use 5.006;
use strict;
use warnings;
use Carp            qw{ croak               };
use Params::Util    qw{ _IDENTIFIER _STRING };
use Data::UUID      qw{ NameSpace_DNS       };
use Perl::Dist::WiX::Base::Component
                    qw{                     };
use Perl::Dist::WiX::Files::Entry
                    qw{                     };
                    

use vars qw{$VERSION @ISA};
BEGIN {
    $VERSION = '0.11_04';
    @ISA = 'Perl::Dist::WiX::Base::Component';
}

use Object::Tiny qw{
    root
    key
    id
    values
    guid
    sitename
    filename
};

#####################################################################
# Constructors for Files::Component

sub new {
    my $self = shift->SUPER::new(@_);

    unless ( _STRING($self->filename) ) {
        croak("Missing or invalid filename param");
    }
    
    unless ( defined $self->guid ) {
        unless ( _STRING($self->sitename) ) {
            croak("Missing or invalid sitename param - cannot generate GUID without one");
        }
        my $guidgen = Data::UUID->new();
        # Make our own namespace...
        my $uuid =  $guidgen->create_from_name(Data::UUID::NameSpace_DNS, $self->sitename);
        #... then use it to create a GUID out of the filename.
        $self->{guid} = uc $guidgen->create_from_name_str($uuid, $self->filename);
        $self->{id} = $self->{guid}; 
        $self->{id} =~ s{-}{_}g;
    }

    $self->{entries} = [];
    $self->{entries}->[0] = new Perl::Dist::WiX::Files::Entry(
        sitename => $self->sitename,
        name     => $self->filename,
    );
    
    return $self;
}


#####################################################################
# Main Methods

sub as_string {
    my $self = shift;
    
    return q{} if (0 == scalar @{$self->{entries}}); 
        
    my $answer = <<END_OF_XML;
<Component Id='C_$self->{id}' Guid='$self->{guid}'>
END_OF_XML
   
    $answer .= $self->SUPER::as_string(2);
    
    $answer .= <<END_OF_XML;
</Component>
END_OF_XML
    
    return $answer;
}

1;