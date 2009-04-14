package Perl::Dist::WiX::RemoveFolder;

#####################################################################
# Perl::Dist::WiX::RemoveFolder - A <Fragment> and <DirectoryRef> tag that
# contains a <RemoveFolder> element.
#
# Copyright 2009 Curtis Jewell
#
# License is the same as perl. See Wix.pm for details.
#
#<<<
use 5.006;
use strict;
use warnings;
use vars              qw( $VERSION );
use Object::InsideOut qw( 
	Perl::Dist::WiX::Base::Fragment
	Perl::Dist::WiX::Base::Component
	Storable
);
use Readonly          qw( Readonly );
use Params::Util      qw( _STRING  );

use version; $VERSION = version->new('0.170_001')->numify;

# Defining at this level so it does not need recreated every time.
Readonly my @ON_OPTIONS => qw(install uninstall both);

#>>>
#####################################################################
# Accessors:
#   on: Whether the directory should be removed on install, uninstall, or both.

my @on : Field : Arg('Name' => 'on', 'Default' => 'uninstall') : Get(get_on);

#####################################################################
# Constructor for RemoveFolder
#
# Parameters: [pairs]
#   id, directory: See Base::Fragment.

sub _pre_init : PreInit {
	my ( $self, $args ) = @_;

	unless ( defined $args->{guid} ) {
		my $id = $args->{id};
		unless ( defined _STRING($id) ) {
			PDWiX::Parameter->throw(
				parameter => 'id',
				where     => '::RemoveFolder->new'
			);
		}
		$args->{guid} = $self->generate_guid("Remove$id");
	}

	return;
} ## end sub _pre_init :

sub _init : Init {
	my $self = shift;

	unless ( $self->check_options( $self->get_on(), @ON_OPTIONS ) ) {
		PDWiX::Parameter->throw(
			parameter => q{on: Must be 'install', 'uninstall', or 'both'},
			where     => '::RemoveFolder->new'
		);
	}

	my $directory_id = $self->get_directory_id();
	
	$self->trace_line( 2,
		    'Creating directory removal entry for directory '
		  . "id D_$directory_id\n" );

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

	my $id = $self->get_component_id();

	return "Remove$id";
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
	my $self = shift;

	my $id           = $self->get_component_id();
	my $directory_id = $self->get_directory_id();
	my $guid         = $self->get_guid();
	my $on           = $self->get_on();
	
	return <<"EOF";
<?xml version='1.0' encoding='windows-1252'?>
<Wix xmlns='http://schemas.microsoft.com/wix/2006/wi'>
  <Fragment Id='Fr_Remove$id'>
    <DirectoryRef Id='D_$directory_id'>
      <Component Id='C_Remove$id' Guid='$guid'>
        <RemoveFolder On="$on"/>
      </Component>
    </DirectoryRef>
  </Fragment>
</Wix>
EOF

} ## end sub as_string

1;
