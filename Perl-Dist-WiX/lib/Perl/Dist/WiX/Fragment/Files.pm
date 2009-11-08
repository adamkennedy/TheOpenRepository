package Perl::Dist::WiX::Fragment::Files;

#####################################################################
# Perl::Dist::WiX::Fragment::Files - A <Fragment> and <DirectoryRef> tag that
# contains <Directory> or <DirectoryRef> elements, which contain <Component> and
# <File> tags.
#
# Copyright 2009 Curtis Jewell
#
# License is the same as perl. See Wix.pm for details.
#
use 5.008001;
use Moose;
use MooseX::Types::Moose qw( Bool );
use Params::Util qw( _INSTANCE );
use File::Spec::Functions qw( abs2rel splitpath catpath catdir splitdir );
use List::MoreUtils qw( uniq );
use Digest::CRC qw( crc32_base64 );
require Perl::Dist::WiX::Exceptions;
require Perl::Dist::WiX::Tag::DirectoryRef;
require Perl::Dist::WiX::DirectoryCache;
require Perl::Dist::WiX::DirectoryTree2;
require WiX3::XML::Component;
require WiX3::XML::Feature;
require WiX3::XML::FeatureRef;
require WiX3::XML::File;
require WiX3::Exceptions;
require File::List::Object;
require Win32::Exe;

our $VERSION = '1.100_001';
$VERSION =~ s/_//ms;

extends 'WiX3::XML::Fragment';
with 'WiX3::Role::Traceable';

has files => (
	is       => 'ro',
	isa      => 'File::List::Object',
	required => 1,
	reader   => 'get_files',
	handles  => {
		'add_files'  => 'add_files',
		'add_file'   => 'add_file',
		'_subtract'  => 'subtract',
		'_get_files' => 'files',
	},
);

has feature => (
	is       => 'bare',
	isa      => 'Maybe[WiX3::XML::Feature]',
	init_arg => undef,
	lazy     => 1,
	reader   => '_get_feature',
	builder  => '_build_feature',
);

sub _build_feature {
	my $self = shift;
	if ( not $self->in_merge_module() ) {
		my $feat = WiX3::XML::Feature->new(
			id      => $self->get_id(),
			level   => 1,
			display => 'hidden',
		);
		$self->add_child_tag($feat);
		return $feat;
	} else {
		return undef;
	}
} ## end sub _build_feature

has can_overwrite => (
	is      => 'ro',
	isa     => Bool,
	default => 0,
	reader  => 'can_overwrite',
);

has in_merge_module => (
	is      => 'ro',
	isa     => Bool,
	default => 0,
);

# This type of fragment needs regeneration.
sub regenerate {
	my $self = shift;
	my @fragment_ids;
	my @files = @{ $self->_get_files() };

	my $id = $self->get_id();
	$self->trace_line( 2, "Regenerating $id\n" );

	$self->clear_child_tags();

  FILE:
	foreach my $file (@files) {
		push @fragment_ids, $self->_add_file_to_fragment($file);
	}

	if ( 0 < scalar @fragment_ids ) {
		push @fragment_ids, $id;
	}

	return uniq @fragment_ids;
} ## end sub regenerate

sub _add_file_to_fragment {
	my $self      = shift;
	my $file_path = shift;
	my $tree      = Perl::Dist::WiX::DirectoryTree2->instance();

	$self->trace_line( 3, "Adding $file_path\n" );

# return () or any fragments that need regeneration retrieved from the cache.
	my ( $directory_final, @fragment_ids );

	my ( $volume, $dirs, $file ) = splitpath( $file_path, 0 );
	my $path_to_find = catdir( $volume, $dirs );

# TODO: Wait until feature tags working right.
#	my @child_tags = $self->_get_feature()->get_child_tags();
	my @child_tags       = $self->get_child_tags();
	my $child_tags_count = scalar @child_tags;

	# Step 1: Search in our own directories exactly.
	#  SUCCESS: Create component and file.

	my $i_step1     = 0;
	my $found_step1 = 0;
	my $directory_step1;
	my $tag_step1;
  STEP1:

	while ( $i_step1 < $child_tags_count and not $found_step1 ) {

		$tag_step1 = $child_tags[$i_step1];
		$i_step1++;

		next STEP1
		  unless ( $tag_step1->isa('Perl::Dist::WiX::Tag::Directory')
			or $tag_step1->isa('Perl::Dist::WiX::Tag::DirectoryRef') );

		# Search for directory.
		$directory_step1 = $tag_step1->search_dir(
			path_to_find => $path_to_find,
			descend      => 1,
			exact        => 1,
		);

		if ( defined $directory_step1 ) {

			$found_step1 = 1;
			$self->_add_file_component( $directory_step1, $file_path );
			return ();
		}
	} ## end while ( $i_step1 < $child_tags_count...)


	# Step 2: Search in the directory tree exactly.
	#  SUCCESS: Create a reference, create component and file.

	my $directory_step2;
  STEP2:

	# Search for directory.
	$directory_step2 = $tree->search_dir(
		path_to_find => $path_to_find,
		descend      => 1,
		exact        => 1,
	);

	if ( defined $directory_step2 ) {

		my $directory_ref_step2 =
		  Perl::Dist::WiX::DirectoryRef->new(
			directory_object => $directory_step2 );

		$self->add_child_tag($directory_ref_step2);
		$self->_add_file_component( $directory_ref_step2, $file_path );
		return ();
	}

# Step 3: Search in our own directories non-exactly.
#  SUCCESS: Create directories, create component and file.
#  NOTE: Check if directories are in cache, and if so, add to directory tree and regenerate.

	my $i_step3     = 0;
	my $found_step3 = 0;
	my $directory_step3;
	my $tag_step3;
  STEP3:

	while ( $i_step3 < $child_tags_count and not $found_step3 ) {

		$tag_step3 = $child_tags[$i_step3];
		$i_step3++;

		next STEP3
		  unless ( $tag_step3->isa('Perl::Dist::WiX::Tag::Directory')
			or $tag_step3->isa('Perl::Dist::WiX::Tag::DirectoryRef') );

		# Search for directory.
		$directory_step3 = $tag_step3->search_dir(
			path_to_find => $path_to_find,
			descend      => 1,
			exact        => 0,
		);

		if ( defined $directory_step3 ) {

			$found_step3 = 1;
			( $directory_final, @fragment_ids ) =
			  $self->_add_directory_recursive( $directory_step3,
				$path_to_find );
			$self->_add_file_component( $directory_final, $file_path );
			return @fragment_ids;
		}
	} ## end while ( $i_step3 < $child_tags_count...)


# Step 4: Search in the directory tree non-exactly.
#  SUCCESS: Create a reference, create directories below it, create component and file.
#  NOTE: Same as Step 3.
#  FAIL: Throw error.

	my $directory_step4;
  STEP3:

	# Search for directory.
	$directory_step4 = $tree->search_dir(
		path_to_find => $path_to_find,
		descend      => 1,
		exact        => 0,
	);

	if ( defined $directory_step4 ) {

		my $directory_ref_step4 =
		  Perl::Dist::WiX::DirectoryRef->new(
			directory_object => $directory_step4 );

# TODO: Wait until feature tags work right.
#		$self->_get_feature()->add_child_tag($directory_ref_step4);
		$self->add_child_tag($directory_ref_step4);
		( $directory_final, @fragment_ids ) =
		  $self->_add_directory_recursive( $directory_ref_step4,
			$path_to_find );
		$self->_add_file_component( $directory_final, $file_path );
		return @fragment_ids;
	} ## end if ( defined $directory_step4)

	PDWiX->throw("Could not add $file_path");
	return ();
} ## end sub _add_file_to_fragment

sub check_duplicates {
	my $self     = shift;
	my $filelist = shift;

	if ( not $self->can_overwrite() ) {
		return $self;
	}

	if ( not defined _INSTANCE( $filelist, 'File::List::Object' ) ) {
		PDWiX::Parameter->throw(
			parameter => 'filelist',
			where => 'Perl::Dist::WiX::Fragment::Files->check_duplicates',
		);
		return 0;
	}

	$self->_subtract($filelist);
	return $self;
} ## end sub check_duplicates

sub _add_directory_recursive {
	my $self             = shift;
	my $tag              = shift;
	my $dir              = shift;
	my $cache            = Perl::Dist::WiX::DirectoryCache->instance();
	my $tree             = Perl::Dist::WiX::DirectoryTree2->instance();
	my $directory_object = $tag;
	my @fragment_ids     = ();

	my $dirs_to_add = abs2rel( $dir, $tag->get_path() );
	my @dirs_to_add = splitdir($dirs_to_add);

	while ( $dirs_to_add[0] eq q{} ) {
		shift @dirs_to_add;
	}

	foreach my $dir_to_add (@dirs_to_add) {
		$directory_object = $directory_object->add_directory(
			name => $dir_to_add,
			id   => crc32_base64(
				catdir( $directory_object->get_path(), $dir_to_add )
			),
		);
		if ( $cache->exists_in_cache($directory_object) ) {
			$tree->add_directory( $directory_object->get_path() );
			push @fragment_ids,
			  $cache->get_previous_fragment($directory_object);
			$cache->delete_cache_entry($directory_object);
		} else {
			$cache->add_to_cache( $directory_object, $self );
		}
	} ## end foreach my $dir_to_add (@dirs_to_add)

	return ( $directory_object, uniq @fragment_ids );
} ## end sub _add_directory_recursive

sub _add_file_component {
	my $self = shift;
	my $tag  = shift;
	my $file = shift;

	# We need a shorter ID than a GUID. CRC32's do that.
	# it does NOT have to be cryptographically perfect,
	# it just has to TRY and be unique over a set of 10,000
	# file names and compoments or so.

	my $revext;                        # Reverse the extension.
	my ( undef, undef, $filename ) = splitpath($file);
	$filename = reverse scalar $filename;
	($revext) = $filename =~ m{\A(.*?)[.]}msx;
	if ( not defined $revext ) {
		$revext = 'Z';
	}

	my $component_id = "${revext}_";
	$component_id .= crc32_base64($file);
	$component_id =~ s{[+]}{_}ms;
	$component_id =~ s{/}{-}ms;

	my @feature_param = ();

	if ( defined $self->_get_feature() ) {
		@feature_param =
		  ( feature => 'Feat_' . $self->_get_feature()->get_id() );
	}

	my $component = WiX3::XML::Component->new(
		path => $file,
		id   => $component_id,
		@feature_param
	);
	my $file_obj;

	# If the file is a .dll or .exe file, check for a version.
	if (( -r $file )
		and (  ( $file =~ m{[.] dll\z}smx )
			or ( $file =~ m{[.] exe\z}smx ) ) )
	{
		my $language;
		my $exe = Win32::Exe->new($file);
		my $vi  = $exe->version_info();
		if ( defined $vi ) {
			$vi->get('OriginalFilename'); # To load the variable used below.
			$language = hex substr $vi->{'cur_trans'}, 0, 4;
			$file_obj = WiX3::XML::File->new(
				source          => $file,
				id              => $component_id,
				defaultlanguage => $language,
			);
		} else {
			$file_obj = WiX3::XML::File->new(
				source => $file,
				id     => $component_id,
			);
		}
	} else {

		# If the file doesn't exist, it gets caught later.
		$file_obj = WiX3::XML::File->new(
			source => $file,
			id     => $component_id,
		);
	}

	$component->add_child_tag($file_obj);
	$tag->add_child_tag($component);

	return 1;
} ## end sub _add_file_component

around 'get_componentref_array' => sub {
	my $orig = shift;
	my $self = shift;

	if ( $self->in_merge_module() ) {
		return $self->$orig();
	} else {
		return $self->_get_feature()->get_componentref_array();
	}
};

no Moose;
__PACKAGE__->meta->make_immutable;

1;
