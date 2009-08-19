package Perl::Dist::WiX::Fragment::CreateFolder;

#####################################################################
# Perl::Dist::WiX::Fragment::CreateFolder - A <Fragment> and <DirectoryRef> tag that
# contains a <CreateFolder> element.
#
# Copyright 2009 Curtis Jewell
#
# License is the same as perl. See Wix.pm for details.
#
use 5.008001;
use Moose;
use Params::Util         qw( _STRING  );
use MooseX::Types::Moose qw( Str      );
use WiX3::XML::CreateFolder;
use WiX3::XML::DirectoryRef;
use WiX3::XML::Component;

our $VERSION = '1.100';
$VERSION = eval { return $VERSION };

extends 'WiX3::XML::Fragment';

has directory_id => (
	is => 'ro',
	isa => Str,
	reader => '_get_directory_id',
	required => 1,
);


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
		%args = @_;
	} else {
		# TODO: Throw an error.
	}
	
	if (not exists $args{'id'}) {
		# TODO: Throw an error.
	}

	if (not exists $args{'directory_id'}) {
		# TODO: Throw an error.
	}

	return { id => "Fr_Create$args{id}", directory_id => $args{'directory_id'} };

}

sub BUILD {
	my $self = shift;
	
	my $id = $self->get_id();
	my $directory_tree = Perl::Dist::WiX::DirectoryTree2->instance();
	$id = substr $id, 9;

	my $directory_id = $self->_get_directory_id();	
	my $directory_object = $directory_tree->get_directory_object("D_$directory_id");
	
	my $tag1 = WiX3::XML::CreateFolder->new();
	my $tag2 = WiX3::XML::Component->new( 
		id => "C_Create$id"
	);
	$tag2->add_child_tag($tag1);
	my $tag3 = WiX3::XML::DirectoryRef->new( 
		directory_object => $directory_object,
	);
	$tag3->add_child_tag($tag2);
	
	$self->add_child_tag($tag3);
	
	$self->trace_line( 2,
		    'Creating directory creation entry for directory '
		  . "id D_$directory_id\n" );
	
	return;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;