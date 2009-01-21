package Perl::Dist::WiX::StartMenu;

use 5.006;
use strict;
use warnings;
use Carp                              qw{ croak               };
use Params::Util                      qw{ _IDENTIFIER _STRING };
use Data::UUID                        qw{ NameSpace_DNS       };
use Perl::Dist::WiX::Base::Fragment   qw{};

use vars qw{$VERSION @ISA};
BEGIN {
    $VERSION = '0.11_05';
    @ISA = 'Perl::Dist::WiX::Base::Fragment';
}

use Object::Tiny qw{
    sitename
};

#####################################################################
# Constructors

sub new {
    my ($class, %params) = @_;

    # Apply required defaults.
    unless ( defined $params{id} ) {
        $params{id} = 'Icons';
    }
    
    unless ( defined $params{directory} ) {
        $params{directory} = 'ApplicationProgramsFolder';
    }

    my $self = $class->SUPER::new(%params);

    unless (_STRING($self->sitename)) {
        croak 'Invalid or missing sitename';
    }
    
    return $self;
}

sub get_component_array {
    my $self = shift;
    
    my $count = scalar @{$self->{components}};
    my @answer;
    my $id;

    push @answer, 'C_RemoveShortcutFolder';
    
    # Get the array for each descendant.
    foreach my $i (0 .. $count - 1) {
        $id = $self->{components}->[$i]->id;
        push @answer,"C_$id"; 
    }


    return $self;
}

sub as_string {
    my ($self) = shift;
    
    # getting the number of items in the array referred to by $self->{components}
    my $count = scalar @{$self->{components}};
    my $string;
    my $s;
    
    $string = <<"EOF";
<?xml version='1.0' encoding='windows-1252'?>
<Wix xmlns='http://schemas.microsoft.com/wix/2006/wi'>
  <Fragment Id='Fr_$self->{id}'>
    <DirectoryRef Id='$self->{directory}'>
EOF

    foreach my $i (0 .. $count - 1) {
        $s = $self->{components}->[$i]->as_string;
        $string .= $self->indent(6, $s);
        $string .= "\n";
    }

    my $guidgen = Data::UUID->new();
    # Make our own namespace...
    my $uuid = $guidgen->create_from_name(Data::UUID::NameSpace_DNS, $self->sitename);
    #... then use it to create a GUID out of the ID.
    my $guid_RSF = uc $guidgen->create_from_name_str($uuid, 'RemoveShortcutFolder');

    $string .= <<'EOF';
      <Component Id='C_RemoveShortcutFolder' Guid='$guid_RSF'>
        <RemoveFolder Id="ApplicationProgramsFolder" On="uninstall" />
      </Component>
    </DirectoryRef>
  </Fragment>
</Wix>
EOF

    return $string;

}

1;