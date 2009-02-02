package Perl::Dist::WiX::CreateFolder;

#####################################################################
# Perl::Dist::WiX::CreateFolder - A <Fragment> and <DirectoryRef> tag that 
# contains a <CreateFolder> element.
#
# Copyright 2009 Curtis Jewell
#
# License is the same as perl. See Wix.pm for details.
#
# $Rev: 5111 $ $Date: 2009-01-29 21:19:23 -0700 (Thu, 29 Jan 2009) $ $Author: csjewell@cpan.org $
# $URL: http://svn.ali.as/cpan/trunk/Perl-Dist-WiX/lib/Perl/Dist/WiX/StartMenu.pm $

use 5.006;
use strict;
use warnings;
use Carp            qw( croak               );
use Params::Util    qw( _IDENTIFIER _STRING );
require Perl::Dist::WiX::Base::Fragment;

use vars qw( $VERSION @ISA );
BEGIN {
    $VERSION = '0.13_01';
    @ISA = 'Perl::Dist::WiX::Base::Fragment';
}

#####################################################################
# Accessors:
#   None.


#####################################################################
# Constructor for CreateFolder
#
# Parameters: [pairs]
#   id, directory: See Base::Filename.

sub new {
    my ($class, %params) = @_;

    my $self = $class->SUPER::new(%params);

    # Check parameters.
    unless (_IDENTIFIER($self->id)) {
        croak 'Invalid or missing id';
    }
    unless (_STRING($self->directory)) {
        croak 'Invalid or missing directory';
    }
    
    return $self;
}

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
    
    return "C_Create$self->{id}";
}

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
    my ($self) = shift;
    
    # getting the number of items in the array referred to by $self->{components}
    my $count = scalar @{$self->{components}};
    my $string;
    my $s;
    
    $string = <<"EOF";
<?xml version='1.0' encoding='windows-1252'?>
<Wix xmlns='http://schemas.microsoft.com/wix/2006/wi'>
  <Fragment Id='Fr_Create$self->{id}'>
    <DirectoryRef Id='D_$self->{directory}'>
      <Component Id='C_Create$self->{id}'>
        <CreateFolder />
      </Component>
    </DirectoryRef>
  </Fragment>
</Wix>
EOF

    return $string;

}

1;
