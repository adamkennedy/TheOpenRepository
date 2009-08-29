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
use File::Spec::Functions qw( abs2rel );
use List::MoreUtils qw( uniq );
require Perl::Dist::WiX::Exceptions;
require WiX3::Exceptions;
require File::List::Object;

our $VERSION = '1.100';
$VERSION = eval { return $VERSION };

extends 'WiX3::XML::Fragment';

has files => (
	is => 'ro',
	isa	=> 'File::List::Object',
	required => 1,
	reader => 'get_files',
	handles => { 
		'add_files'     => 'add_files', 
		'add_file'      => 'add_file',
		'_subtract'     => 'subtract',
		'_get_files'    => 'files', 
	},
);

has can_overwrite => (
	is => 'ro',
	isa => Bool,
	default => 0,
	reader => 'can_overwrite',
);

# This type of fragment needs regeneration.
sub regenerate {
	my $self = shift;
	my $answer;
	my $caused_regeneration = 0;
	my @fragments_to_regenerate;
	my $firsttime = 1;
	my @files = @{$self->_get_files()};
	
	while ($firsttime or $caused_regeneration) {
	
		my $id = $self->get_id();
		print "Regenerating $id\n";
	
		$self->clear_child_tags();
		
		$firsttime = 0;
		$caused_regeneration = 1;
		foreach my $file (@files) {
			push @fragments_to_regenerate, $self->_add_file($file);
		}
		
		foreach my $fragment (@fragments_to_regenerate) {
			$caused_regeneration = 1;
			$fragment->regenerate();
		}
	};

	return;
}

sub _add_file {
	my $self = shift;
	my $file_path = shift;
	my $tree = Perl::Dist::WiX::DirectoryTree2->instance();

	# return () or any fragments that need regeneration retrieved from the cache.
	my ($directory_final, @fragments);
	
	my ($volume, $dirs, $file) = splitpath($file_path, 0);
	my $path_to_find = catpath($volume, $dirs, undef);

	my @child_tags = $self->get_child_tags();
	my $child_tags_count = scalar @child_tags;
		
	# Step 1: Search in our own directories exactly.
	#  SUCCESS: Create component and file.

	my $i_step1 = 0;	
	my $found_step1 = 0;
	my $directory_step1;
	my $tag_step1;
  STEP1:
	while ($i_step1 < $child_tags_count and not $found_step1) {

		$tag_step1 = $child_tags[$i_step1];
		$i_step1++;
	
		next STEP1 unless ($tag_step1->isa('Perl::Dist::WiX::Directory') or $tag_step1->isa('Perl::Dist::WiX::DirectoryRef'));
	
		# Search for directory.
		$directory_step1 = $tag_step1->search_dir(
			path_to_find => $path_to_find,
			descend      => 1,
			exact        => 1,
		);
		
		if (defined $directory_step1) {
			$found_step1 = 1;
			$self->add_file_component($directory_step1, $file_path);
			return ();
		}
	}
	
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
		
	if (defined $directory_step2) {
		my $directory_ref_step2 = Perl::Dist::WiX::DirectoryRef->new(
			directory_object => $directory_step2
		);
		
		$self->add_child_tag($directory_ref_step2);
		$self->add_file_component($directory_ref_step2, $file_path);
		return ();
	}
	

	# Step 3: Search in our own directories non-exactly.
	#  SUCCESS: Create directories, create component and file.
	#  NOTE: Check if directories are in cache, and if so, add to directory tree and regenerate.
	
	my $i_step3 = 0;	
	my $found_step3 = 0;
	my $directory_step3;
	my $tag_step3;
  STEP3:
	while ($i_step3 < $child_tags_count and not $found_step3) {

		$tag_step3 = $child_tags[$i_step3];
		$i_step3++;
	
		next STEP3 unless ($tag_step3->isa('Perl::Dist::WiX::Directory') or $tag_step3->isa('Perl::Dist::WiX::DirectoryRef'));
	
		# Search for directory.
		$directory_step3 = $tag_step3->search_dir(
			path_to_find => $path_to_find,
			descend      => 1,
			exact        => 0,
		);
		
		if (defined $directory_step3) {
			$found_step3 = 1;
			($directory_final, @fragments) = $self->_add_directory_recursive($directory_step3, $path_to_find);		
			$self->_add_file_component($directory_final, $file_path);
			return @fragments;
		}
	}
	
	
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
		exact        => 1,
	);
		
	if (defined $directory_step4) {
	
		my $directory_ref_step4 = Perl::Dist::WiX::DirectoryRef->new(
			directory_object => $directory_step4
		);
		
		$self->add_child_tag($directory_ref_step4);
		($directory_final, @fragments) = $self->_add_directory_recursive($directory_ref_step4, $path_to_find);		
		$self->_add_file_component($directory_final, $file_path);
		return @fragments;
	}

	PDWiX->throw("Could not add $file_path");
	return ();
	
}

sub check_duplicates {
	my $self = shift;
	my $filelist = shift;

	if (not $self->can_overwrite()) {
		return $self;
	}

	if (not defined _INSTANCE($filelist, 'File::List::Object')) {
		PDWiX::Parameter->throw(
			parameter => 'filelist',
			where => 'Perl::Dist::WiX::Fragment::Files->check_duplicates',
		);
		return 0;
	}

	$self->_subtract($filelist);
	return $self;
}

sub _add_directory_recursive {
	my $self = shift;
	my $tag = shift;
	my $dir = shift;
	my $cache = Perl::Dist::WiX::DirectoryCache->instance();
	my $tree = Perl::Dist::WiX::DirectoryTree2->instance();
	my $directory_object = $tag;
	my @fragments = ();
	
	my @dirs_to_add = splitpath(abs2rel($dir, $tag->get_path()));
	foreach my $dir_to_add (@dirs_to_add) {
		$directory_object = $directory_object->add_directory(name => $dir_to_add);
		if ($cache->exists_cache_entry($directory_object)) {
			$tree->add_directory($directory_object->get_path());
			push @fragments, $cache->previous_cache_entry($directory_object);
			$cache->delete_cache_entry($directory_object);
		} else {
			$cache->add_cache_entry($directory_object, $self);
		}
	}
	
	return ($directory_object, uniq @fragments);
}

sub _add_file_component {
	my $self = shift;
	my $tag = shift;
	my $file = shift;
	
	my $component = WiX3::XML::Component->new();
	my $file_obj = Perl::Dist::WiX::File->new(
		guid => $component->get_guid(),
		source => $file,
	);
	
	$component->add_child_tag($file_obj);
	$tag->add_child_tag($component);

}

no Moose;
__PACKAGE__->meta->make_immutable;

1;