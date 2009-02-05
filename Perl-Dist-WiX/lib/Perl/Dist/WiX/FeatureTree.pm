package Perl::Dist::WiX::FeatureTree;

####################################################################
# Perl::Dist::WiX::FeatureTree - Tree of MSI features.
#
# Copyright 2009 Curtis Jewell
#
# License is the same as perl. See Wix.pm for details.
#
# $Rev$ $Date$ $Author$
# $URL$

use 5.008;
use strict;
use warnings;
use Carp qw( croak                 );
use Params::Util qw( _IDENTIFIER _CLASSISA );
use Scalar::Util qw( weaken                );
require Perl::Dist::WiX::Feature;
require Perl::Dist::WiX::Misc;

use vars qw( $VERSION @ISA );

BEGIN {
    $VERSION = '0.13_01';
    @ISA     = 'Perl::Dist::WiX::Misc';
}

#####################################################################
# Accessors:
#   features: Returns the first level of the features tree as an arrayref.

use Object::Tiny qw{
  features
};

#####################################################################
# Constructor for FeatureTree
#

########################################
# new
# Parameters: [pairs]
#   parent: Perl::Dist::WiX object to get information from.
#     [saved as a weak reference.]

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new( @_ );

    unless ( _CLASSISA( ref $self->{parent}, 'Perl::Dist::WiX' ) ) {
        croak 'Missing or invalid parent parameter';
    }

    # Do this so as not to create a garbage collection loop.
    weaken( $self->{parent} );

    # Start the tree.
    print "Creating feature tree...\n";
    $self->{features} = [];
    if ( defined $self->{parent}->{msi_feature_tree} ) {
        croak
"Complex feature tree not implemented in Per::Dist::WiX $VERSION.";
    } else {
        $self->features->[0] = Perl::Dist::WiX::Feature->new(
            id          => 'Complete',
            title       => $self->{parent}->app_ver_name,
            description => 'The complete package.',
            level       => 1,
        )->add_components( $self->{parent}->get_component_array );
    }

    return $self;
} ## end sub new

#####################################################################
# Main Methods

########################################
# search($id)
# Parameters:
#   $id: Id of feature to find.
# Returns:
#   Feature object found or undef.

sub search {
    my ( $self, $id_to_find ) = @_;

    # Check parameters.
    unless ( _IDENTIFIER( $id_to_find ) ) {
        croak 'Missing or invalid id parameter';
    }

    # Check each of our branches.
    my $count = scalar @{ $self->features };
    my $answer;
    foreach my $i ( 0 .. $count - 1 ) {
        $answer = $self->features->[$i]->search( $id_to_find );
        if ( defined $answer ) {
            return $answer;
        }
    }

    # If we get here, we did not find a feature.
    return undef;
} ## end sub search

########################################
# as_string
# Parameters:
#   None.
# Returns:
#   String representing features contained in this object.

sub as_string {
    my $self = shift;

    # Get the strings for each of our branches.
    my $count = scalar @{ $self->features };
    my $answer;
    foreach my $i ( 0 .. $count - 1 ) {
        $answer .= $self->features->[$i]->as_string;
    }

    return $self->indent( 4, $answer );
} ## end sub as_string

1;
