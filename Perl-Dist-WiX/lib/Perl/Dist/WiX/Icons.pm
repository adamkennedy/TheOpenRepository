package Perl::Dist::WiX::Icons;

####################################################################
# Perl::Dist::WiX::Icons - Object that represents a list of <Icon> tags.
#
# Copyright 2009 Curtis Jewell
#
# License is the same as perl. See Wix.pm for details.
#
#<<<
use 5.006;
use strict;
use warnings;
use Object::InsideOut      qw( Perl::Dist::WiX::Misc Storable );
use Params::Util           qw( _STRING   );
use File::Spec::Functions  qw( splitpath );
use vars                   qw( $VERSION  );

use version; $VERSION = qv('0.14');
#>>>
#####################################################################
# Attributes

my @icons : Field : Name(icons);

#####################################################################
# Constructors for Icons
#
# Parameters: [none]

sub _init : Init {
	my $self = shift;

	# Initialize our icons area.
	@icons[ ${$self} ] = [];

	return $self;
}


#####################################################################
# Main Methods

########################################
# add_icon
# Parameters:
#   pathname_icon: Path of icon.
#   pathname_target: Path of icon's target.
# Returns:
#   Id of icon.

sub add_icon {
	my ( $self, $pathname_icon, $pathname_target ) = @_;

	# Check parameters
	unless ( defined $pathname_target ) {
		$pathname_target = 'Perl.msi';
	}
	unless ( defined _STRING($pathname_target) ) {
		PDWiX->throw('Invalid pathname_target parameter');
	}
	unless ( defined _STRING($pathname_icon) ) {
		PDWiX->throw('Invalid pathname_icon parameter');
	}

	# Find the type of target.
	my ($target_type) = $pathname_target =~ m{\A.*[.](.+)\z}msx;
	$self->trace_line( 2,
		"Adding icon $pathname_icon with target type $target_type.\n" );

	# If we have an icon already, return it.
	my $icon = $self->search_icon( $pathname_icon, $target_type );
	if ( defined $icon ) { return $icon; }

	# Get Id made.
	my ( undef, undef, $filename_icon ) = splitpath($pathname_icon);
	my $id = substr $filename_icon, 0, -4;
	$id =~ s/[^A-Za-z0-9]/_/gmxs;      # Substitute _ for anything
	                                   # non-alphanumeric.
	$id .= ".$target_type";

	# Add icon to our list.
	push @{ $icons[ ${$self} ] },
	  { file        => $pathname_icon,
		target_type => $target_type,
		id          => $id
	  };

	return $id;
} ## end sub add_icon

########################################
# search_icon
# Parameters:
#   pathname_icon: Path of icon to search for.
#   target_type: Target type to search for.
# Returns:
#   Id of icon.

sub search_icon {
	my ( $self, $pathname_icon, $target_type ) = @_;

	# Check parameters
	unless ( defined $target_type ) {
		$target_type = 'msi';
	}
	unless ( defined _STRING($target_type) ) {
		PDWiX->throw('Invalid target_type parameter');
	}
	unless ( defined _STRING($pathname_icon) ) {
		PDWiX->throw('Invalid pathname_icon parameter');
	}

	if ( 0 == scalar @{ $icons[ ${$self} ] } ) { return undef; }

	# Print each icon
	foreach my $icon ( @{ $icons[ ${$self} ] } ) {
		if (    ( $icon->{file} eq $pathname_icon )
			and ( $icon->{target_type} eq $target_type ) )
		{
			return $icon->{id};
		}
	}

	return undef;
} ## end sub search_icon


########################################
# as_string
# Parameters:
#   None.
# Returns:
#   String containing <Icon> tags defined by this object.

sub as_string {
	my $self = shift;
	my $answer;

	# Short-circuit
	if ( 0 == scalar @{ $icons[ ${$self} ] } ) { return q{}; }

	# Print each icon
	foreach my $icon ( @{ $icons[ ${$self} ] } ) {
		$answer .=
		  "  <Icon Id='I_$icon->{id}' SourceFile='$icon->{file}' />\n";
	}

	return $answer;
} ## end sub as_string

1;
