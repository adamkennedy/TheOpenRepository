package Perl::Dist::WiX::IconArray;

####################################################################
# Perl::Dist::WiX::IconArray - Object that represents a list of <Icon> tags.
#
# Copyright 2009 Curtis Jewell
#
# License is the same as perl. See Wix.pm for details.
#
use 5.008001;
use Moose;
use MooseX::AttributeHelpers;
use Params::Util           qw( _STRING   );
use File::Spec::Functions  qw( splitpath );
require Perl::Dist::WiX::Icon;

our $VERSION = '1.090';
$VERSION = eval { return $VERSION };

has _icon => (
	metaclass => 'Collection::Array',
	is        => 'rw',
	isa       => 'ArrayRef[Perl::Dist::WiX::Icon]',
	default   => sub { [] },
    provides  => {
        'push'     => '_push_icon',
		'count'    => '_count_icons',
		'elements' => '_get_icon_array',
	},
);



#####################################################################
# Main Methods

########################################
# add_icon($pathname_icon, $pathname_target)
# Parameters:
#   $pathname_icon: Path of icon.
#   $pathname_target: Path of icon's target.
# Returns:
#   Id of icon.

sub add_icon {
	my ( $self, $pathname_icon, $pathname_target ) = @_;

	# Check parameters
	unless ( defined $pathname_target ) {
		$pathname_target = 'Perl.msi';
	}
	unless ( defined _STRING($pathname_target) ) {
		PDWiX::Parameter->throw(
			parameter => 'pathname_target',
			where     => '::Icons->add_icon'
		);
	}
	unless ( defined _STRING($pathname_icon) ) {
		PDWiX::Parameter->throw(
			parameter => 'pathname_icon',
			where     => '::Icons->add_icon'
		);
	}

	# Find the type of target.
	my ($target_type) = $pathname_target =~ m{\A.*[.](.+)\z}msx;
# TODO: Make this work.
#	$self->trace_line( 2,
#		"Adding icon $pathname_icon with target type $target_type.\n" );

	# If we have an icon already, return it.
	my $icon = $self->search_icon( $pathname_icon, $target_type );
	if ( defined $icon ) { return $icon; }

	# Get Id made.
	my ( undef, undef, $filename_icon ) = splitpath($pathname_icon);
	my $id = substr $filename_icon, 0, -4;
	$id =~ s/[^A-Za-z0-9]/_/gmxs;      # Substitute _ for anything
	                                   # non-alphanumeric.
	$id .= ".$target_type.ico";

	# Add icon to our list.
	$self->_push_icon(Perl::Dist::WiX::Icon->new(
	  sourcefile  => $pathname_icon,
	  target_type => $target_type,
	  id          => $id
	));

	return $id;
} ## end sub add_icon

########################################
# search_icon($pathname_icon, $target_type)
# Parameters:
#   $pathname_icon: Path of icon to search for.
#   $target_type: Target type to search for.
# Returns:
#   Id of icon.

sub search_icon {
	my ( $self, $pathname_icon, $target_type ) = @_;

	# Check parameters
	unless ( defined $target_type ) {
		$target_type = 'msi';
	}
	unless ( defined _STRING($target_type) ) {
		PDWiX::Parameter->throw(
			parameter => 'target_type',
			where     => '::Icons->search_icon'
		);
	}
	unless ( defined _STRING($pathname_icon) ) {
		PDWiX::Parameter->throw(
			parameter => 'pathname_icon',
			where     => '::Icons->search_icon'
		);
	}

	if ( 0 == $self->_count_icons() ) { return undef; }

	# Print each icon
	foreach my $icon ( $self->_get_icon_array() ) {
		if (    ( $icon->get_sourcefile eq $pathname_icon )
			and ( $icon->get_target_type eq $target_type ) )
		{
			return $icon->get_id;
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
	if ( 0 == $self->_count_icons ) { return q{}; }

	# Print each icon
	foreach my $icon ( $self->_icon_array() ) {
		my $id = $icon->get_id();
		my $file = $icon->get_sourcefile();
		$answer .=
		  "  <Icon Id='I_$id' SourceFile='$file' />\n";
	}

	return $answer;
} ## end sub as_string

no Moose;
__PACKAGE__->meta->make_immutable;

1;
