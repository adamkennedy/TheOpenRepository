package Perl::Dist::WiX::Registry;

use 5.006;
use strict;
use warnings;
use Carp                              qw{ croak               };
use Params::Util                      qw{ _IDENTIFIER _STRING };
use Perl::Dist::WiX::Base::Fragment   qw{};
use Perl::Dist::WiX::Registry::Key    qw{};
use Perl::Dist::WiX::Registry::Entry  qw{};

use vars qw{$VERSION @ISA};
BEGIN {
    $VERSION = '0.11_06';
    @ISA = 'Perl::Dist::WiX::Base::Fragment';
}

use Object::Tiny qw{
    sitename
};


#####################################################################
# Constructors for Registry

sub new {
    my ($class, %params) = @_;

    # Apply defaults
    unless ( defined $params{id} ) {
        $params{id} = 'Registry';
    }

    my $self = $class->SUPER::new(%params);
}

sub get_component_array {
    my $self = shift;
    
    my $count = scalar @{$self->{components}};
    my @answer;
    my $id;
    
    # Get the array for each descendant.
    foreach my $i (0 .. $count - 1) {
        $id = $self->{components}->[$i]->id;
        push @answer,"C_$id"; 
    }

    return @answer;
}

sub add_key {
    my ($self, %params) = @_;

    # Check parameters.
    unless ( _STRING($params{id}) ) {
        croak("Missing or invalid name");
    }
    unless ( _STRING($params{key}) ) {
        croak("Missing or invalid name");
    }

    # Set defaults.
    unless ( _STRING($params{root}) ) {
        $params{root} = 'HKLM';
    }

    # Search for key...
    my $key = undef;
    # getting the number of items in the array referred to by $self->{components}
    my $count = scalar @{$self->{components}};

    foreach my $i (0 .. $count - 1) {
        if ($self->{components}->[$i]->is_key($params{root}, $params{key})) {
            $key = $self->{components}->[$i];
            last; 
        }
    }

    if (not defined $key)
    {
        $key = Perl::Dist::WiX::Registry::Key->new(
            id       => $params{id}, 
            root     => $params{root}, 
            key      => $params{key}, 
            sitename => $self->sitename);
        $self->add_component($key);
    }
    
    $key->add_entry(
        Perl::Dist::WiX::Registry::Entry->entry(@params{'name', 'value', 'action', 'value_type'}));
    
    return $self;
}

1;
