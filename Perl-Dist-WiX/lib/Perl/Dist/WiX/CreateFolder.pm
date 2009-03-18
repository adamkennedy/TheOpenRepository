package Perl::Dist::WiX::CreateFolder;

#####################################################################
# Perl::Dist::WiX::CreateFolder - A <Fragment> and <DirectoryRef> tag that
# contains a <CreateFolder> element.
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
use Params::Util      qw( _STRING  );

use version; $VERSION = qv('0.160');
#>>>
#####################################################################
# Accessors:
#   None.


#####################################################################
# Constructor for CreateFolder
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
				where     => '::CreateFolder->new'
			);
		}
		$args->{guid} = $self->generate_guid("Create$id");
	}

	return;
} ## end sub _pre_init :

sub _init : Init {
	my $self = shift;

	my $directory_id = $self->get_directory_id();

	$self->trace_line( 2,
		    'Creating directory creation entry for directory '
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

	return "Create$id";
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

	return <<"EOF";
<?xml version='1.0' encoding='windows-1252'?>
<Wix xmlns='http://schemas.microsoft.com/wix/2006/wi'>
  <Fragment Id='Fr_Create$id'>
    <DirectoryRef Id='D_$directory_id'>
      <Component Id='C_Create$id' Guid='$guid'>
        <CreateFolder />
      </Component>
    </DirectoryRef>
  </Fragment>
</Wix>
EOF

} ## end sub as_string

1;
