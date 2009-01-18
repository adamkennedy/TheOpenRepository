package Perl::Dist::WiX::Registry::Entry;

use 5.006;
use strict;
use warnings;
use Carp                             qw{ croak               };
use Params::Util                     qw{ _IDENTIFIER _STRING };
use Perl::Dist::WiX::Base::Entry     qw{};

use vars qw{$VERSION @ISA};
BEGIN {
    $VERSION = '0.11_04';
    @ISA = 'Perl::Dist::WiX::Entry';
}

use Object::Tiny qw{
    action
    value_type
    value_name
    value_data
};

#####################################################################
# Constructor for Registry::Entry

sub new {
    my $self = shift->SUPER::new(@_);

    # Apply defaults
    unless ( defined $self->value_type ) {
        $self->{value_type} = 'expandable';
    }

    # Check params
    unless ( _IDENTIFIER($self->action) ) {
        croak("Missing or invalid value_name param");
    }
    unless ( _IDENTIFIER($self->value_type) ) {
        croak("Invalid value_type param");
    }
    unless ( _IDENTIFIER($self->value_name) ) {
        croak("Missing or invalid value_name param");
    }
    unless ( _STRING($self->value_data) ) {
        croak("Missing or invalid value_data param");
    }

    return $self;
}

# Shortcut constructor for an environment variable
sub entry {
    return $_[0]->new(
        value_name => $_[1],
        value_data => $_[2],
        action     => $_[3],
        value_type => $_[4]
    );
}

#####################################################################
# Accessor

sub as_string {
    my $self = shift;

    return join( '<RegistryValue',
        q{  Action='} . $self->action,
        q{' Type='}   . $self->value_type,
        q{' Name='}   . $self->value_name,
        q{' Value='}  . $self->value_data . q{' />},
    );
}

1;