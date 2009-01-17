package Perl::Dist::WiX::Files::Entry;

use 5.006;
use strict;
use warnings;
use Carp                qw{ croak               };
use Params::Util        qw{ _IDENTIFIER _STRING };
use Data::UUID          qw{ NameSpace_DNS       };
use Perl::Dist::WiX::Base::Entry
                        qw{                     };

use vars qw{$VERSION @ISA};
BEGIN {
    $VERSION = '0.11_03';
    @ISA = 'Perl::Dist::WiX::Base::Entry';
}

use Object::Tiny qw{
    id
    name
    sitename
    keyfile
};



#####################################################################
# Constructor for Files::Entry

sub new {
    my $self = shift->SUPER::new(@_);

    # Check params
    unless ( _STRING($self->name) ) {
        croak("Missing or invalid value_name param");
    }
    unless ( _STRING($self->sitename) ) {
        croak("Missing or invalid sitename param - cannot generate GUID without one");
    }

    # Apply defaults
    unless ( defined $self->keyfile ) {
        $self->{keyfile} = 0;
    }

    unless ( defined $self->id ) {
        my $guidgen = Data::UUID->new();
        # Make our own namespace...
        my $uuid = $guidgen->create_from_name(Data::UUID::NameSpace_DNS, $self->sitename);
        #... then use it to create a GUID out of the filename.
        $self->{id} = uc $guidgen->create_from_name_str($uuid, $self->name);
        $self->{id} =~ s{-}{_}g;
    }

    return $self;
}

#####################################################################
# Accessor

sub as_string {
    my $self = shift;

    # Name= parameter defults to the filename portion of the Source parameter,
    # so it isn't needed.
    return q{<File Id='F_} . $self->id .
        q{' Source='}      . $self->name .
#        q{' Keyfile='}    . ($self->keyfile ? 'Yes' : 'No') . 
        q{' />};
}

1;
