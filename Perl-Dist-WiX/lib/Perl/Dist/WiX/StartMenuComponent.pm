package Perl::Dist::WiX::StartMenuComponent;

#####################################################################
# Perl::Dist::WiX::StartMenuComponent - A <Component> tag that contains a start menu <Shortcut>.
#
# Copyright 2009 Curtis Jewell
#
# License is the same as perl. See Wix.pm for details.
#
# WARNING: Class not meant to be created directly, except through
# Perl::Dist::WiX::StartMenu.
#
# StartMenu components contain the entry, so there is no WiX::Entry sub class
#
#<<<
use 5.008001;
use strict;
use warnings;
use vars              qw( $VERSION            );
use Object::InsideOut qw(
	Perl::Dist::WiX::Base::Component
	Perl::Dist::WiX::Base::Entry
	Storable
);
use Params::Util      qw( _IDENTIFIER _STRING );

use version; $VERSION = version->new('0.190')->numify;

#>>>
#####################################################################
# Accessors:
#   none.

## no critic 'ProhibitUnusedVariables'
my @name : Field : Arg(name);
my @description : Field : Arg(description);
my @target : Field : Arg(target);
my @working_dir : Field : Arg(working_dir);
my @menudir_id : Field : Arg(menudir_id);
my @icon_id : Field : Arg(icon_id);

#####################################################################
# Constructor for StartMenuComponent
#
# Parameters: [pairs]
#   id, guid: See Base::Component.
#   name: Name attribute to the <Shortcut> tag.
#   description: Description attribute to the <Shortcut> tag.
#   target: Target of the <Shortcut> tag.
#   working_dir: WorkingDirectory attribute of the <Shortcut> tag.
#   menudir_id: Directory attribute of the <CreateFolder> tag.
#
# See http://wix.sourceforge.net/manual-wix3/wix_xsd_shortcut.htm
# and http://wix.sourceforge.net/manual-wix3/wix_xsd_createfolder.htm

sub _pre_init : PreInit {
	my ( $self, $args ) = @_;

	unless ( _STRING( $args->{name} ) ) {
		PDWiX::Parameter->throw(
			parameter => 'name',
			where     => '::StartMenuComponent->new'
		);
	}

	unless ( _STRING( $args->{description} ) ) {
		$args->{description} = $args->{name};
	}

	unless ( _STRING( $args->{id} ) ) {
		PDWiX::Parameter->throw(
			parameter => 'id',
			where     => '::StartMenuComponent->new'
		);
	}

	unless ( _STRING( $args->{guid} ) ) {
		$args->{guid} = $self->generate_guid( $args->{id} );
	}

	return;
} ## end sub _pre_init :

sub _init : Init {
	my $self      = shift;
	my $object_id = ${$self};

	unless ( _STRING( $target[$object_id] ) ) {
		PDWiX::Parameter->throw(
			parameter => 'target',
			where     => '::StartMenuComponent->new'
		);
	}
	unless ( _STRING( $working_dir[$object_id] ) ) {
		PDWiX::Parameter->throw(
			parameter => 'working_dir',
			where     => '::StartMenuComponent->new'
		);
	}
	unless ( _STRING( $menudir_id[$object_id] ) ) {
		PDWiX::Parameter->throw(
			parameter => 'menudir_id',
			where     => '::StartMenuComponent->new'
		);
	}
	unless ( _STRING( $icon_id[$object_id] ) ) {
		PDWiX::Parameter->throw(
			parameter => 'icon_id',
			where     => '::StartMenuComponent->new'
		);
	}

	$self->trace_line( 3, "Adding Icon for $target[$object_id]\n" );

	return;
} ## end sub _init :

#####################################################################
# Main Methods

########################################
# as_string
# Parameters:
#   None.
# Returns:
#   String representation of the <Component> and <Shortcut> tags represented
#   by this object.

sub as_string {
	my $self      = shift;
	my $object_id = ${$self};

	my $id   = $self->get_component_id();
	my $guid = $self->get_guid();

	return <<"END_OF_XML";
<Component Id='C_S_$id' Guid='$guid'>
  <Shortcut Id='S_$id'
            Name='$name[$object_id]'
            Description='$description[$object_id]'
            Target='$target[$object_id]'
            Icon='I_$icon_id[$object_id]'
            WorkingDirectory='D_$working_dir[$object_id]' />
  <CreateFolder Directory="$menudir_id[$object_id]" />
</Component>
END_OF_XML

} ## end sub as_string

1;
