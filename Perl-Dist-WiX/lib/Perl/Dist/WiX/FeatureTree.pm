package Perl::Dist::WiX::FeatureTree;

####################################################################
# Perl::Dist::WiX::FeatureTree - Tree of MSI features.
#
# Copyright 2009 Curtis Jewell
#
# License is the same as perl. See Wix.pm for details.
#
#<<<
use     5.008;
use     strict;
use     warnings;
use     vars                     qw( $VERSION                       );
use     Object::InsideOut        qw( Perl::Dist::WiX::Misc Storable );
use     Params::Util             qw( _IDENTIFIER _CLASSISA          );
use     Scalar::Util             qw( weaken                         );
require Perl::Dist::WiX::Feature;

use version; $VERSION = qv('0.15');
#>>>
#####################################################################
# Accessors:

my @parent : Field : Arg(Name => 'parent', Required => 1);
my @features : Field : Name(features) : Get(get_features);

#####################################################################
# Constructor for FeatureTree
#

########################################
# new
# Parameters: [pairs]
#   parent: Perl::Dist::WiX object to get information from.
#     [saved as a weak reference.]

sub _init : Init {
	my $self      = shift;
	my $object_id = ${$self};

	unless ( _CLASSISA( ref $parent[$object_id], 'Perl::Dist::WiX' ) ) {
		PDWiX->throw('Missing or invalid parent parameter');
	}

	# Do this so as not to create a garbage collection loop.
	weaken( $parent[$object_id] );

	# Start the tree.
	$self->trace_line( 0, "Creating feature tree...\n" );
	$features[$object_id] = [];
	if ( defined $parent[$object_id]->{msi_feature_tree} ) {
		PDWiX->throw( 'Complex feature tree not implemented in '
			  . "Perl::Dist::WiX $VERSION." );
	} else {
		$features[$object_id]->[0] = Perl::Dist::WiX::Feature->new(
			id          => 'Complete',
			title       => $parent[$object_id]->app_ver_name,
			description => 'The complete package.',
			level       => 1,
		)->add_components( $parent[$object_id]->get_component_array );
	}

	return $self;
} ## end sub _init :

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
	my $object_id = ${$self};

	# Check parameters.
	unless ( _IDENTIFIER($id_to_find) ) {
		PDWiX->throw('Missing or invalid id parameter');
	}

	# Check each of our branches.
	my $count = scalar @{ $features[$object_id] };
	my $answer;
	foreach my $i ( 0 .. $count - 1 ) {
		$answer = $features[$object_id]->[$i]->search($id_to_find);
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
	my $self      = shift;
	my $object_id = ${$self};

	# Get the strings for each of our branches.
	my $count = scalar @{ $features[$object_id] };
	my $answer;
	foreach my $i ( 0 .. $count - 1 ) {
		$answer .= $features[$object_id]->[$i]->as_string;
	}

	return $self->indent( 4, $answer );
} ## end sub as_string

1;
