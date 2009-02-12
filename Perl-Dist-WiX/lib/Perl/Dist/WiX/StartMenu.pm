package Perl::Dist::WiX::StartMenu;

#####################################################################
# Perl::Dist::WiX::StartMenu - A <Fragment> and <DirectoryRef> tag that
# contains start menu <Shortcut>.
#
# Copyright 2009 Curtis Jewell
#
# License is the same as perl. See Wix.pm for details.
#
# $Rev$ $Date$ $Author$
# $URL$
#<<<
use     5.006;
use     strict;
use     warnings;
use     Carp            qw( croak               );
use     Params::Util    qw( _IDENTIFIER _STRING );
use     Data::UUID      qw( NameSpace_DNS       );
require Perl::Dist::WiX::Base::Fragment;

use vars qw( $VERSION @ISA );
BEGIN {
    $VERSION = '0.13_01';
    @ISA = 'Perl::Dist::WiX::Base::Fragment';
}
#>>>
#####################################################################
# Accessors:
#   sitename: Returns the sitename passed in to new.

use Object::Tiny qw{
  sitename
};

#####################################################################
# Constructor for StartMenu
#
# Parameters: [pairs]
#   id, directory: See Base::Filename.
#   sitename: The name of the site that is hosting the download.

sub new {
    my ( $class, %params ) = @_;

    # Apply required defaults.
    unless ( defined $params{id} ) {
        $params{id} = 'Icons';
    }
    unless ( defined $params{directory} ) {
        $params{directory} = 'ApplicationProgramsFolder';
    }

    my $self = $class->SUPER::new( %params );

    # Check parameters.
    unless ( _STRING( $self->sitename ) ) {
        croak 'Invalid or missing sitename';
    }
    unless ( _IDENTIFIER( $self->id ) ) {
        croak 'Invalid or missing id';
    }
    unless ( _STRING( $self->directory ) ) {
        croak 'Invalid or missing directory';
    }

    return $self;
} ## end sub new

#####################################################################
# Main Methods

########################################
# get_component_array
# Parameters:
#   None.
# Returns:
#   Array of the Id attributes of the components within this object.

sub get_component_array {
    my $self = shift;

    my $count = scalar @{ $self->{components} };
    my @answer;
    my $id;

    push @answer, 'RemoveShortcutFolder';

    # Get the array for each descendant.
    foreach my $i ( 0 .. $count - 1 ) {
        $id = $self->{components}->[$i]->id;
        push @answer, "S_$id";
    }

    return @answer;
} ## end sub get_component_array

sub search_file {
    return undef;
}

sub check_duplicates {
    return undef;
}

########################################
# as_string
# Parameters:
#   None.
# Returns:
#   String representation of the <Fragment> and other tags represented
#   by this object.

sub as_string {
    my ( $self ) = shift;

# getting the number of items in the array referred to by $self->{components}
    my $count = scalar @{ $self->{components} };
    my $string;
    my $s;

    # Short-circuit.
    return q{} if (0 == $count);
    
    # Start printing.
    $string = <<"EOF";
<?xml version='1.0' encoding='windows-1252'?>
<Wix xmlns='http://schemas.microsoft.com/wix/2006/wi'>
  <Fragment Id='Fr_$self->{id}'>
    <DirectoryRef Id='$self->{directory}'>
EOF

    # Get component strings.
    foreach my $i ( 0 .. $count - 1 ) {
        $s = $self->{components}->[$i]->as_string;
        $string .= $self->indent( 6, $s );
        $string .= "\n";
    }

    # Make our own namespace...
    my $guidgen = Data::UUID->new();
    my $uuid =
      $guidgen->create_from_name( Data::UUID::NameSpace_DNS,
        $self->sitename );

    #... then use it to create a GUID out of the ID.
    my $guid_RSF =
      uc $guidgen->create_from_name_str( $uuid, 'RemoveShortcutFolder' );

    # Finish printing.
    $string .= <<"EOF";
      <Component Id='C_RemoveShortcutFolder' Guid='$guid_RSF'>
        <RemoveFolder Id="$self->{directory}" On="uninstall" />
      </Component>
    </DirectoryRef>
  </Fragment>
</Wix>
EOF

    return $string;

} ## end sub as_string

1;
