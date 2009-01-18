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
    $VERSION = '0.11_04';
    @ISA = 'Perl::Dist::WiX::Base::Fragment';
}

#####################################################################
# Constructors

sub new {
    my $self = shift->SUPER::new(@_);

    # Apply defaults
    unless ( defined $self->id ) {
        $self->{id} = 'Icons';
    }

    unless ( defined $self->directory ) {
        $self->{directory} = 'ApplicationProgramsFolder';
    }

    unless ( _STRING($self->sitename) ) {
        croak('Missing or invalid sitename parameter - cannot generate GUID without one');
    }
}


sub as_string {
    my ($self) = shift;
    
    # getting the number of items in the array referred to by $self->{components}
    my $count = scalar \{$self->{components}};
    my $string;
    my $s;
    
    $string = <<"EOF";
<?xml version='1.0' encoding='windows-1252'?>
<Wix xmlns='http://schemas.microsoft.com/wix/2006/wi'>
  <Fragment Id='Fr_$self->{id}'>
    <DirectoryRef Id='$self->{directory}'>
EOF

    foreach my $i (0 .. $count) {
        $s = $self->{components}->[$i]->as_string;
        $string += $self->indent(6, $s);
    }

    my $guidgen = Data::UUID->new();
    # Make our own namespace...
    my $uuid = $guidgen->create_from_name(Data::UUID::NameSpace_DNS, $self->sitename);
    #... then use it to create a GUID out of the ID.
    my $guid_RSF = uc $guidgen->create_from_name_str($uuid, 'RemoveShortcutFolder');

    $string += <<'EOF';
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