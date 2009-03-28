package Perl::Dist::WiX::Feature;

####################################################################
# Perl::Dist::WiX::Feature - Object representing <Feature> tag.
#
# Copyright 2009 Curtis Jewell
#
# License is the same as perl. See Wix.pm for details.
#
#<<<
use 5.006;
use strict;
use warnings;
use vars              qw( $VERSION                       );
use Object::InsideOut qw( Perl::Dist::WiX::Misc Storable );
use Params::Util      qw( _INSTANCE _STRING _NONNEGINT   );

use version; $VERSION = version->new('0.163')->numify;
#>>>
#####################################################################
# Accessors:
#   features: Returns a reference to an array of features contained
#     within this feature.
#   componentrefs: Returns a reference to an array of component
#     references contained within this feature.
#
#  id, title, description, default, idefault, display, directory, absent, advertise, level:
#    See new.

my @id : Field : Arg(Name => 'id', Required => 1);
my @title : Field : Arg(Name => 'title', Required => 1);
my @description : Field : Arg(Name => 'description', Required => 1);
my @level : Field : Arg(Name => 'level', Required => 1);
my @default : Field : Arg(default);
my @idefault : Field : Arg(idefault);
my @display : Field : Arg(display);
my @directory : Field : Arg(directory);
my @absent : Field : Arg(absent);
my @advertise : Field : Arg(advertise);

my @default_settings : Field : Name(default_settings);
my @features : Field : Name(features);
my @componentrefs : Field : Name(componentrefs) : Get(get_componentrefs);

#####################################################################
# Constructor for Feature
#
# Parameters: [pairs]
#   id: Id parameter to the <Feature> tag (required)
#   title: Title parameter to the <Feature> tag (required)
#   description: Description parameter to the <Feature> tag (required)
#   level: Level parameter to the <Feature> tag (required)
#   default: TypicalDefault parameter to the <Feature> tag
#   idefault: InstallDefault parameter to the <Feature> tag
#   display: Display parameter to the <Feature> tag
#   directory: ConfigurableDirectory parameter to the <Feature> tag
#   absent: Absent parameter to the <Feature> tag
#   advertise: AllowAdvertise parameter to the <Feature> tag
#
# See http://wix.sourceforge.net/manual-wix3/wix_xsd_feature.htm
#
# Defaults:
#   default     => 'install',
#   idefault    => 'local',
#   display     => 'expand',
#   directory   => 'INSTALLDIR',
#   absent      => 'disallow'
#   advertise   => 'no'

sub _init : Init {
	my $self      = shift;
	my $object_id = ${$self};

	# Check required parameters.
	unless ( _STRING( $id[$object_id] ) ) {
		PDWiX::Parameter->throw(
			parameter => 'id',
			where     => '::Feature->new'
		);
	}
	unless ( _STRING( $title[$object_id] ) ) {
		PDWiX::Parameter->throw(
			parameter => 'title',
			where     => '::Feature->new'
		);
	}
	unless ( _STRING( $description[$object_id] ) ) {
		PDWiX::Parameter->throw(
			parameter => 'description',
			where     => '::Feature->new'
		);
	}
	unless ( defined _NONNEGINT( $level[$object_id] ) ) {
		PDWiX::Parameter->throw(
			parameter => 'level',
			where     => '::Feature->new'
		);
	}

	my $default_settings = 0;

	# Set defaults
	unless ( _STRING( $default[$object_id] ) ) {
		$default[$object_id] = 'install';
		$default_settings++;
	}
	unless ( _STRING( $idefault[$object_id] ) ) {
		$idefault[$object_id] = 'local';
		$default_settings++;
	}
	unless ( _STRING( $display[$object_id] ) ) {
		$display[$object_id] = 'expand';
		$default_settings++;
	}
	unless ( _STRING( $directory[$object_id] ) ) {
		$directory[$object_id] = 'INSTALLDIR';
		$default_settings++;
	}
	unless ( _STRING( $absent[$object_id] ) ) {
		$absent[$object_id] = 'disallow';
		$default_settings++;
	}
	unless ( _STRING( $advertise[$object_id] ) ) {
		$advertise[$object_id] = 'no';
		$default_settings++;
	}

	$default_settings[$object_id] = $default_settings;

	# Set up empty arrayrefs
	$features[$object_id]      = [];
	$componentrefs[$object_id] = [];

	return $self;
} ## end sub _init :

#####################################################################
# Main Methods

########################################
# add_feature
# Parameters:
#   $feature: [Feature object] Feature to add as a subfeature of this one.
# Returns:
#   Object being acted on (chainable)

sub add_feature {
	my ( $self, $feature ) = @_;
	my $object_id = ${$self};

	unless ( _INSTANCE( $feature, 'Perl::Dist::WiX::Feature' ) ) {
		PDWiX::Parameter->throw(
			parameter => 'feature',
			where     => '::Feature->add_feature'
		);
	}

	push @{ $features[$object_id] }, $feature;

	return $self;
} ## end sub add_feature

########################################
# add_components
# Parameters:
#   @componentids: List of component ids to add to this feature.
# Returns:
#   Object being acted on (chainable)

sub add_components {
	my ( $self, @componentids ) = @_;
	my $object_id = ${$self};

	push @{ $componentrefs[$object_id] }, @componentids;

	return $self;
}

########################################
# search($id_to_find)
# Parameters:
#   $id_to_find: Id of feature to find.
# Returns:
#   Feature object with given Id.

sub search {
	my ( $self, $id_to_find ) = @_;
	my $object_id = ${$self};

	# Check parameters.
	unless ( _IDENTIFIER($id_to_find) ) {
		PDWiX::Parameter->throw(
			parameter => 'id_to_find',
			where     => '::Feature->search'
		);
	}

	my $id = $id[$object_id];

	# Success!
	if ( $id_to_find eq $id ) {
		return $self;
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
#   String representation of the <Feature> tag represented
#   by this object and the <Feature> and <ComponentRef> tags
#   contained in this object.

sub as_string {
	my $self      = shift;
	my $object_id = ${$self};

	my $f_count = scalar @{ $features[$object_id] };
	my $c_count = scalar @{ $componentrefs[$object_id] };

	return q{} if ( 0 == $f_count + $c_count );

	my ( $string, $s );
#<<<
	$string =
		q{<Feature Id='}    . $id[$object_id]
	  . q{' Title='}        . $title[$object_id]
	  . q{' Description='}  . $description[$object_id]
	  . q{' Level='}        . $level[$object_id];
#>>>
	my %hash = (
		advertise => $advertise[$object_id],
		absent    => $absent[$object_id],
		directory => $directory[$object_id],
		display   => $display[$object_id],
		idefault  => $idefault[$object_id],
		default   => $default[$object_id],
	);

	foreach my $key ( keys %hash ) {
		if ( not defined $hash{$key} ) {
			$self->trace_line( 0,
				"$key in feature $id[$object_id] is undefined.\n" );
		}
	}

	if ( $default_settings[$object_id] != 6 ) {
#<<<
		$string .=
			q{' AllowAdvertise='}         . $advertise[$object_id]
		  . q{' Absent='}                 . $absent[$object_id]
		  . q{' ConfigurableDirectory='}  . $directory[$object_id]
		  . q{' Display='}                . $display[$object_id]
		  . q{' InstallDefault='}         . $idefault[$object_id]
		  . q{' TypicalDefault='}         . $default[$object_id];
#>>>
	}

# TODO: Allow condition subtags.

	if ( ( $c_count == 0 ) and ( $f_count == 0 ) ) {
		$string .= qq{' />\n};
	} else {
		$string .= qq{'>\n};

		foreach my $i ( 0 .. $f_count - 1 ) {
			$s .= $features[$object_id]->[$i]->as_string;
		}
		if ( defined $s ) {
			$string .= $self->indent( 2, $s );
		}
		$string .= $self->_componentrefs_as_string;
		$string .= qq{\n};

		$string .= qq{</Feature>\n};
	} ## end else [ if ( ( $c_count == 0 )...

	return $string;

} ## end sub as_string

sub _componentrefs_as_string {
	my $self      = shift;
	my $object_id = ${$self};

	my ( $string, $ref );
	my $c_count = scalar @{ $componentrefs[$object_id] };

	if ( $c_count == 0 ) {
		return q{};
	}

	foreach my $i ( 0 .. $c_count - 1 ) {
		$ref = $componentrefs[$object_id]->[$i];
		$string .= qq{<ComponentRef Id='C_$ref' />\n};
	}

	return $self->indent( 2, $string );
} ## end sub _componentrefs_as_string

1;
