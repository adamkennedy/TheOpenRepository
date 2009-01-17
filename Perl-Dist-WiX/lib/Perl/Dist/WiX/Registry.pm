package Perl::Dist::WiX::Registry;

use 5.006;
use strict;
use warnings;
use Carp                             qw{ croak               };
use Params::Util                     qw{ _IDENTIFIER _STRING };
use Data::UUID                       qw{ NameSpace_DNS };
use Perl::Dist::WiX::Base::Fragment  qw{};
use Perl::Dist::WiX::Base::Component qw{};
use Perl::Dist::WiX::Base::Entry     qw{};

use vars qw{$VERSION @ISA};
BEGIN {
    $VERSION = '0.11_03';
    @ISA = 'Perl::Dist::WiX::Base::Fragment';
}

#####################################################################
# Constructors for Registry

sub new {
    my $self = shift->SUPER::new(@_);

    # Apply defaults
    unless ( defined $self->id ) {
        $self->{id} = 'F_Registry';
    }
}

sub add_key {

    my $self = shift;
    my %params = @_;

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
    my $count = scalar \{$self->{components}};

    foreach my $i (0 .. $count) {
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

package Perl::Dist::WiX::Registry::Key;

use vars qw{$VERSION @ISA};
BEGIN {
    $VERSION = '0.10_01';
    @ISA = 'Perl::Dist::WiX::Component';
}

use Object::Tiny qw{
    root
    key
    id
    values
    guid
    sitename
    entries_num
};

#####################################################################
# Constructors for Registry::Key

sub new {
    my $self = shift->SUPER::new(@_);

    # Apply defaults
    unless ( defined $self->root ) {
        $self->{root} = 'HKLM';
    }
    
    unless ( defined $self->guid ) {
        $self->create_guid_from_id;
    }

    # Check params
    unless ( _IDENTIFIER($self->root) ) {
        croak("Missing or invalid root param");
    }

    unless ( _STRING($self->key) ) {
        croak("Missing or invalid subkey param");
    }

    unless ( _STRING($self->id) ) {
        croak("Missing or invalid id param");
    }
    
    return $self;
}

# Shortcut constructor for an environment variable
sub add_environment {
    return $_[0]->new(
        key       => 'SYSTEM\CurrentControlSet\Control\Session Manager\Environment',
        id        => 'Registry',
        @_
    );
}


sub add_entry {
    my ($self, $name, $value, $action, $value_type) = @_;  

    unless ( _STRING($name) ) {
        croak("Missing or invalid name");
    }

    unless ( _STRING($value) ) {
        croak("Missing or invalid value");
    }
    
    $self->add_entry( 
        Perl::Dist::WiX::Registry::Entry->entry($name, $value, $action, $value_type));
    
    return $self;  
}

sub is_key {
    my ($self, $root, $key) = @_;
    
    return 0 if (uc $key ne uc $self->key);
    return 0 if (uc $root ne uc $self->root);
    return 1;
}

#####################################################################
# Main Methods

sub as_string {
    my $self = shift;
    
    return q{} if ($self->entries_num == 0); 

    $self->{key} = uc $self->{key};
    
    my $answer = <<END_OF_XML;
<Component Id='C_$self->{id}' Guid='$self->{guid}'>
  <RegistryKey Root='$self->{root}' Key='$self->{key}'>
END_OF_XML
   
    $answer += $self->SUPER::as_string(4);
    
    $answer += <<END_OF_XML;
  </RegistryKey>
</Component>
END_OF_XML
    
    return $answer;
}

package Perl::Dist::WiX::Registry::Entry;

use vars qw{$VERSION @ISA};
BEGIN {
    $VERSION = '0.10_01';
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
        croak("Missing or invalid value_type param");
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
