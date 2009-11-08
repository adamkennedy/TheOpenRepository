package Perl::Dist::WiX::Tag::DirectoryRef;

#####################################################################
# Perl::Dist::WiX::Tag::DirectoryRef - Extends <DirectoryRef> tags to make them
# easily searchable.
#
# Copyright 2009 Curtis Jewell
#
# License is the same as perl. See WiX.pm for details.
#

use 5.008001;
use Moose;
use MooseX::Types::Moose qw( Str );
use File::Spec::Functions qw( catdir abs2rel );
use Params::Util qw( _STRING _INSTANCE );
require Perl::Dist::WiX::Tag::Directory;

our $VERSION = '1.100_001';
$VERSION =~ s/_//ms;

extends 'WiX3::XML::DirectoryRef';

sub get_directory_object {
	my $self = shift;
	my $id   = shift;

	my $self_id = $self->get_directory_id();

	return $self if ( $id eq $self_id );
	my $return;

  SUBDIRECTORY:
	foreach my $object ( $self->get_child_tags() ) {
		next SUBDIRECTORY
		  if not _INSTANCE( $object, 'Perl::Dist::WiX::Tag::Directory' );
		$return = $object->get_directory_object($id);
		return $return if defined $return;
	}

	return undef;
} ## end sub get_directory_object

sub search_dir {
	my $self = shift;
	my %args;

	if ( @_ == 1 && 'HASH' eq ref $_[0] ) {
		%args = %{ $_[0] };
	} elsif ( @_ % 2 == 0 ) {
		%args = @_;
	} else {

#		print "Argument problem\n";
		# Throw error.
	}

	# Set defaults for parameters.
	my $path_to_find = _STRING( $args{'path_to_find'} )
	  || PDWiX::Parameter->throw(
		parameter => 'path_to_find',
		where     => '::DirectoryRef->search_dir'
	  );
	my $descend = $args{descend} || 1;
	my $exact   = $args{exact}   || 0;
	my $path    = $self->get_path();

	return undef unless defined $path;

# TODO: Make trace_line work.
#	$self->trace_line( 3, "Looking for $path_to_find\n" );
#	$self->trace_line( 4, "  in:      $path.\n" );
#	$self->trace_line( 5, "  descend: $descend exact: $exact.\n" );

	# If we're at the correct path, exit with success!
	if ( ( defined $path ) && ( $path_to_find eq $path ) ) {

#		$self->trace_line( 4, "Found $path.\n" );
#print "Found $path.\n" ;
		return $self;
	}

	# Quick exit if required.
	return undef unless $descend;

	# Do we want to continue searching down this direction?
	my $subset = "$path_to_find\\" =~ m{\A\Q$path\E\\}msx;
	if ( not $subset ) {

#		$self->trace_line( 4, "Not a subset in: $path.\n" );
#		$self->trace_line( 5, "  To find: $path_to_find.\n" );
		return undef;
	}

	# Check each of our branches.
	my @tags = $self->get_child_tags();
	my $answer;

  TAG:
	foreach my $tag (@tags) {
		next TAG unless $tag->isa('Perl::Dist::WiX::Tag::Directory');

		my $x = ref $tag;
		my $y = $tag->get_path();

		$answer = $tag->search_dir( \%args );
		if ( defined $answer ) {
			return $answer;
		}
	} ## end foreach my $tag (@tags)

	# If we get here, we did not find a lower directory.
	return $exact ? undef : $self;
} ## end sub search_dir

sub _add_directory_recursive {
	my $self         = shift;
	my $path_to_find = shift;
	my $dir_to_add   = shift;

	# Should not happen, but checking to make sure we bottom out,
	# rather than going into infinite recursion.
	if ( length $path_to_find < 4 ) {
		return undef;
	}

	my $directory = $self->search_dir(
		path_to_find => $path_to_find,
		descend      => 1,
		exact        => 1,
	);

	if ( defined $directory ) {
		return $directory->add_directory(
			parent => $directory,
			name   => $dir_to_add,

			# TODO: Check for other needs.
		);
	} else {
		my ( $volume, $dirs, undef ) = splitpath( $path_to_find, 1 );
		my @dirs              = splitdir($dirs);
		my $dir_to_add_down   = pop @dirs;
		my $path_to_find_down = catpath( $volume, catdir(@dirs), undef );
		my $dir =
		  $self->_add_directory_recursive( $path_to_find_down,
			$dir_to_add_down );
		return $dir->add_directory( name => $dir_to_add );

	}
} ## end sub _add_directory_recursive

sub add_directory {
	my $self = shift;

	my $new_dir = Perl::Dist::WiX::Tag::Directory->new(
		parent => $self,
		@_
	);
	$self->add_child_tag($new_dir);

	return $new_dir;
}


no Moose;
__PACKAGE__->meta->make_immutable;

1;
