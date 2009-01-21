package Perl::Dist::WiX::Registry::Key;

use 5.006;
use strict;
use warnings;
use Carp                              qw{ croak               };
use Params::Util                      qw{ _IDENTIFIER _STRING };
use Perl::Dist::WiX::Base::Component  qw{};
use Perl::Dist::WiX::Registry::Entry  qw{};

use vars qw{$VERSION @ISA};
BEGIN {
    $VERSION = '0.11_06';
    @ISA = 'Perl::Dist::WiX::Base::Component';
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
    my $class = shift;
    
    return $class->new(
        key       => 'SYSTEM\CurrentControlSet\Control\Session Manager\Environment',
        id        => 'Registry',
        @_
    );
}


sub add_registry_entry {
    my ($self, $name, $value, $action, $value_type) = @_;  
    
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
    
    return q{} if (scalar @{$self->{entries}} == 0); 

    $self->{root} = uc $self->{root};
    
    my $answer = <<END_OF_XML;
<Component Id='C_$self->{id}' Guid='$self->{guid}'>
  <RegistryKey Root='$self->{root}' Key='$self->{key}'>
END_OF_XML
   
    $answer .= $self->SUPER::as_string(4);
    
    $answer .= <<END_OF_XML;
  </RegistryKey>
</Component>
END_OF_XML
    
    return $answer;
}

1;