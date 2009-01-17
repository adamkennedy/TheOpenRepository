package Perl::Dist::WiX::Base::Component;

use 5.006;
use strict;
use warnings;
use Carp                  qw( croak             );
use Params::Util          qw( _CLASSISA _STRING );
use Data::UUID            qw( NameSpace_DNS     );
use Perl::Dist::WiX::Misc qw();

use vars qw{$VERSION @ISA};
BEGIN {
    $VERSION = '0.11_03';
    @ISA = 'Perl::Dist::WiX::Misc';
}

use Object::Tiny qw{
    id
    guid
    sitename
};

#####################################################################
# Constructors for Component

sub new {
    my $self = shift->SUPER::new(@_);
    
    $self->{entries} = [];
    
    return $self;
}

sub add_entry {
    my ($self, $entry) = shift;
    
    if (not defined _CLASSISA(ref $entry, 'Perl::Dist::WiX::Base::Entry')) {
        croak 'Not adding a valid component';
    }
    
    # getting the number of items in the array referred to by $self->{entries}
    my $i = scalar @{$self->{entries}};
    
    $self->{entries}->[$i] = $entry;
    
    return $self;
}

sub create_guid_from_id {
    my $self = shift;

    unless ( _STRING($self->sitename) ) {
        croak("Missing or invalid sitename param - cannot generate GUID without one");
    }
    unless ( _STRING($self->id) ) {
        croak("Missing or invalid id param - cannot generate GUID without one");
    }
    my $guidgen = Data::UUID->new();
    # Make our own namespace...
    my $uuid = $guidgen->create_from_name(Data::UUID::NameSpace_DNS, $self->sitename);
    #... then use it to create a GUID out of the ID.
    $self->{guid} = uc $guidgen->create_from_name_str($uuid, $self->id);
    
    return 1;
}

sub as_string {
    my ($self) = shift;
    my $spaces = shift;
    
    # getting the number of items in the array referred to by $self->{entries}
    my $count = scalar @{$self->{entries}};
    my $string;
    my $s;

    foreach my $i (0 .. $count - 1) {
        $s = $self->{entries}->[$i]->as_string;
        $string .= $self->indent($spaces, $s);
        $string .= "\n";
    }

    return $string;
}

1;