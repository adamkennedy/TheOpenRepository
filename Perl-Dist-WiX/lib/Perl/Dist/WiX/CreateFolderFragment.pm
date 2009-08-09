package Perl::Dist::WiX::CreateFolderFragment;

#####################################################################
# Perl::Dist::WiX::CreateFolderFragment - A <Fragment> and <DirectoryRef> tag that
# contains a <CreateFolder> element.
#
# Copyright 2009 Curtis Jewell
#
# License is the same as perl. See Wix.pm for details.
#
#<<<
use 5.008001;
use Moose;
use vars              qw( $VERSION );
use Params::Util      qw( _STRING  );
use WiX3::XML::CreateFolder;
use WiX3::XML::DirectoryRef;
use WiX3::XML::Component;

use version; $VERSION = version->new('1.000')->numify;

extends 'WiX3::XML::Fragment';

#####################################################################
# Constructor for CreateFolder
#
# Parameters: [pairs]
#   id, directory: See Base::Fragment.

sub BUILDARGS {
	my $class = shift;
	my %args;
	
	if ( @_ == 1 && 'HASH' eq ref $_[0] ) {
		%args = %{$_[0]};
	} elsif ( 0 == @_ % 2 ) {
		%args = ( @_ );
	} else {
		# TODO: Throw an error.
	}
	
	if (not exists $args{'id'}) {
		# TODO: Throw an error.
	}
	
	if (not exists $args{'directory_tree'}) {
		# TODO: Throw an error.
	}

	if (not exists $args{'directory_id'}) {
		# TODO: Throw an error.
	}

	# TODO: Throw an error if directory_tree is not the correct type.
	
	my $id = $args{'id'};
	my $directory_tree = $args{'directory_tree'};
	my $directory_id = $args{'directory_id'};	

	my $directory_object = $directory_tree->get_directory_object('D_$directory_id');
	
	my $tag1 = WiX3::XML::CreateFolder->new();
	my $tag2 = WiX3::XML::Component->new( 
		id => "C_Create$id", 
		child_tags => [ $tag1 ] 
	);
	my $tag3 = WiX3::XML::DirectoryRef->new( 
		directory_object = $directory_tree->get_directory_object('D_$directory_id'),
		child_tags => [ $tag2 ] 
	);
	
	$class->trace_line( 2,
		    'Creating directory creation entry for directory '
		  . "id D_$directory_id\n" );
	
	return { id => "Fr_Create$id" };

}
