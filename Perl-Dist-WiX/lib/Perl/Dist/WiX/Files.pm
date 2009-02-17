package Perl::Dist::WiX::Files;
{
####################################################################
# Perl::Dist::WiX::Files - <Fragment> tag that contains
# <DirectoryRef> tags
#
# Copyright 2009 Curtis Jewell
#
# License is the same as perl. See Wix.pm for details.
#
#<<<
use     5.006;
use     strict;
use     warnings;
use     vars                  qw( $VERSION                              );
use     Object::InsideOut     qw(
    Perl::Dist::WiX::Base::Fragment
    Storable
);
use     Carp                  qw( croak                                 );
use     Params::Util          qw( _IDENTIFIER _STRING _INSTANCE _ARRAY0 );
use     Data::UUID            qw( NameSpace_DNS                         );
use     File::Spec::Functions qw( splitpath catpath catdir              );
require Perl::Dist::WiX::DirectoryTree;
require Perl::Dist::WiX::Files::DirectoryRef;

use version; $VERSION = qv('0.13_02');
#>>>
#####################################################################
# Accessors:
#   see new.

	my @directory_tree : Field : Arg(directory_tree) : Get(directory_tree);

#####################################################################
# Constructor for Files
#
# Parameters: [pairs]
#   directory_tree: [Wix::DirectoryTree object] The initial directory tree.

	sub _init : Init {
		my $self = shift;

		# Check parameters
		unless (
			_INSTANCE(
				$self->directory_tree, 'Perl::Dist::WiX::DirectoryTree'
			) )
		{
			croak('Missing or invalid directory_tree parameter');
		}

		return $self;
	} ## end sub _init :

########################################
# add_files(@files)
# Parameters:
#   @files: List of filenames to add.
# Returns:
#   Object being operated on (chainable).

	sub add_files {
		my ( $self, @files ) = @_;

# Each file could be a directory or have a newline, so fix that and add the files.
		foreach my $file (@files) {
			chomp $file;
			next if not -f $file;
			if ( not defined $self->add_file($file) ) {
				croak "Could not add $file";
			}
		}

		return $self;
	} ## end sub add_files

########################################
# add_file($file)
# Parameters:
#   $file: Filename to add.
# Returns:
#   Files::Component object added or undef.

	sub add_file {
		my ( $self, $file ) = @_;
		my ( $directory_obj, $directory_ref_obj, $file_obj, $subpath ) =
		  ( undef, undef, undef, undef );

		# Check parameters.
		unless ( _STRING($file) ) {
			croak('Missing or invalid file parameter');
		}

		# Get the file path.
		my ( $vol, $dirs, $filename ) = splitpath($file);
		my $path = catdir( $vol, $dirs );

		$self->trace_line( 3, "Adding file $file.\n" );

		# Remove ending backslash.
		if ( substr( $path, -1 ) eq q{\\} ) {
			$path = substr $path, 0, -1;
		}

# 1. Is there a Directory{Ref} for this path in this object?

# Check if we have a Directory{Ref} directly contained with the appropriate path.
		$directory_ref_obj = $self->_search_refs(
			path_to_find => $path,
			descend      => 1,
			exact        => 1
		);
		if ( defined $directory_ref_obj ) {

			# Yes, we do. Add the file to this Directory{Ref}.
			$self->trace_line( 4,
				"Stage 1 - Adding file to Directory{Ref} for $path.\n" );
			$file_obj = $directory_ref_obj->add_file(
				sitename => $self->sitename,
				filename => $file,
			);
			return $file_obj;
		}

# 2. Is there another Directory to create a reference of?
		$self->trace_line( 5, "Stage 1 - Unsuccessful.\n" );

		# Check if we have a Directory in the tree to take a reference of.
		$directory_obj = $self->directory_tree->search_dir(
			path_to_find => $path,
			descend      => 1,
			exact        => 1
		);
		if ( defined $directory_obj ) {

			# Make a DirectoryRef, and attach it.
			$subpath = $directory_obj->get_path;
			$self->trace_line( 4,
				" Stage 2 - Creating DirectoryRef at $subpath.\n" );
			$directory_ref_obj = Perl::Dist::WiX::Files::DirectoryRef->new(
				directory_object => $directory_obj,
			);
			$self->add_component($directory_ref_obj);

			$self->trace_line( 5, "  Adding file $file.\n" );

			# Add the file.
			$file_obj = $directory_ref_obj->add_file(
				filename => $file,
			);
			return $file_obj;
		} ## end if ( defined $directory_obj)

# 3. Check for a higher directory in the directory tree and in the .
		$self->trace_line( 5, "Stage 2 - Unsuccessful.\n" );

		# Check if we have a Directory in the tree to take a reference of.
		$directory_obj = $self->directory_tree->search_dir(
			path_to_find => $path,
			descend      => 1,
			exact        => 0
		);

		# Check if we have a DirectoryRef in the object to refer to.
		$directory_ref_obj = $self->_search_refs(
			path_to_find => $path,
			descend      => 1,
			exact        => 0
		);

		# Which one do we want to use?
		my $use = -1;

 # Determine which one of these 2 to use
 # $use = 1 means use $directory_obj, $use = 0 means use $directory_ref_obj.
		if ( not defined $directory_obj ) {
			if ( not defined $directory_ref_obj ) {
				$use = -1;
			} else {
				$use = 0;
			}
		} else {
			if ( not defined $directory_ref_obj ) {
				$use = 1;
			} else {
				if ( $directory_obj->get_path eq $directory_ref_obj->get_path ) {
                    # Use directory_ref if the paths found are equal.
					$use = 0;               
				} else {
					$use = $directory_obj->is_child_of($directory_ref_obj);
				}
			}
		} ## end else [ if ( not defined $directory_obj)

		# Now use the one that's "lower" in the directory tree.
		if ( $use == 0 ) {

			# Using $directory_ref_obj [from this object]
			$subpath = $directory_ref_obj->get_path;
			$self->trace_line( 5,
"Stage 3a - Creating Directory within Directory{Ref} for $subpath.\n"
			);
			$self->trace_line( 5, "  Adding path $path.\n" );
			$self->trace_line( 5, "  Adding file $file.\n" );

			# Create the directory objects and add the file.
			$directory_obj = $directory_ref_obj->add_directory_path($path);
			$file_obj      = $directory_obj->add_file(
				filename => $file,
			);
			return $file_obj;
		} elsif ( $use == 1 ) {

			# Using $directory_obj [from DirectoryTree object]
			$subpath = $directory_obj->get_path;
			$self->trace_line( 5,
"Stage 3b - Creating Directory within Directory for $subpath.\n"
			);
			$self->trace_line( 5, "  Adding path $path.\n" );
			$self->trace_line( 5, "  Adding file $file.\n" );

			# Create the directory objects and add the file.
			$directory_ref_obj = Perl::Dist::WiX::Files::DirectoryRef->new(
				directory_object => $directory_obj,
			);
			$self->add_component($directory_ref_obj);
			$directory_obj = $directory_ref_obj->add_directory_path($path);
			$file_obj      = $directory_obj->add_file(
				sitename => $self->sitename,
				filename => $file,
			);
			return $file_obj;
		} else {
			$self->trace_line( 5, "Stage 3 - Unsuccessful.\n" );

			# Completely unsuccessful.
			return undef;
		}
	} ## end sub add_file

# Gets a list of paths "above" the currect directory specified in
# $volume and $dirs.

	sub _get_possible_paths {
		my ( $self, $volume, $dirs ) = @_;

		# Get our list of directories.
		my @directories = splitdir($dirs);

		# Get rid of empty entries at the beginning or end.
		while ( $directories[-1] eq q{} ) {
			pop @directories;
		}
		while ( $directories[0] eq q{} ) {
			shift @directories;
		}

		my $dir;
		my @answers;

		# Until we get to the last level...
		while ( $#directories > 1 ) {

			# Remove a level and create its path.
			pop @directories;
			$dir = catdir( $volume, catdir(@directories) );

			# Add it to the answers list.
			push @answers, $dir;
		}

		return @answers;
	} ## end sub _get_possible_paths

# Searches our contained DirectoryRefs for a path.

	sub _search_refs {
		my $self       = shift;
		my $params_ref = {@_};

		# Set defaults for parameters.
		my $path_to_find = $params_ref->{path_to_find}
		  || croak 'No path to find.';
		my $descend = $params_ref->{descend} || 1;
		my $exact   = $params_ref->{exact}   || 0;

		my $answer = undef;

		# How many descendants do we have?
		my $count = scalar @{ $self->get_components };

		# Pass the search down to each our descendants.
		foreach my $i ( 0 .. $count - 1 ) {
			$answer = $self->get_components->[$i]->search_dir(
				path_to_find => $path_to_find,
				descend      => $descend,
				exact        => $exact,
			);

			# Exit if one of our descendants is successful.
			return $answer if defined $answer;
		}

		# We were unsuccessful.
		return undef;
	} ## end sub _search_refs

########################################
# search_file($filename)
# Parameters:
#   $filename: Filename to search for.
# Returns:
#   Files::Component object found or undef.

	sub search_file {
		my ( $self, $filename ) = @_;
		my $answer = undef;

		# Check parameters.
		unless ( _STRING($filename) ) {
			croak('Missing or invalid filename parameter');
		}

		# How many descendants do we have?
		my $count = scalar @{ $self->get_components };

		# Pass the search down to each our descendants.
		foreach my $i ( 0 .. $count - 1 ) {
			$answer = $self->get_components->[$i]->search_file($filename);

			# Exit if one of our descendants is successful.
			return $answer if defined $answer;
		}

		# We were unsuccessful.
		return undef;
	} ## end sub search_file

########################################
# check_duplicates($files_ref)
# Parameters:
#   $files_ref: arrayref of filenames to remove from this object.
# Returns:
#   Object being operated on (chainable).
# Action:
#   Removes filenames listed in $files_ref from this object if they're in it.

	sub check_duplicates {
		my ( $self, $files_ref ) = @_;
		my $answer;
		my ( $object, $index, $pathname_fixed );

		# Check parameters.
		unless ( _ARRAY0($files_ref) ) {
			croak('Missing or invalid files_ref parameter');
		}

		# For each file in the list...
		foreach my $pathname ( @{$files_ref} ) {

			# For a .AAA file, find the original file instead.
			if ( $pathname =~ m{\.AAA\z}ms ) {
				$pathname_fixed = substr $pathname, 0, -4;
			} else {
				$pathname_fixed = $pathname;
			}

			# Try and find the file.
			$answer = $self->search_file($pathname_fixed);

			# Delete the original file if found.
			if ( defined $answer ) {
				( $object, $index ) = @{$answer};
				$self->trace_line( 4,
					    "Deleting reference $index at "
					  . $object->get_path
					  . "\n" );
				$object->delete_filenum($index);
			}
		} ## end foreach my $pathname ( @{$files_ref...

		return $self;
	} ## end sub check_duplicates

########################################
# get_component_array
# Parameters:
#   None.
# Returns:
#   Array of the Id attributes of the components within this object.

	sub get_component_array {
		my $self = shift;
		my @answer;

		# Get the array for each descendant.
		my $count = scalar @{ $self->get_components };
		foreach my $i ( 0 .. $count - 1 ) {
			push @answer, $self->get_components->[$i]->get_component_array;
		}

		return @answer;
	} ## end sub get_component_array

########################################
# as_string
# Parameters:
#   None.
# Returns:
#   String containing fragment defined by this object
#   and DirectoryRef objects contained in this object.

	sub as_string {
		my $self = shift;
		my ( $string, $s );

		my $components = $self->get_components;

		# How many descendants do we have?
		my $count = scalar @{$components};

		# Short circuit.
		if ( $count == 0 ) {
			$self->trace_line( 2, "No components in fragment $self->{id}" );
			return q{};
		}

        my $id = $self->get_fragment_id();
        
		# Start our fragment.
		$string = <<"EOF";
<?xml version='1.0' encoding='windows-1252'?>
<Wix xmlns='http://schemas.microsoft.com/wix/2006/wi'>
  <Fragment Id='Fr_$id'>
EOF

		# Get the string for each descendant.
		foreach my $i ( 0 .. $count - 1 ) {
			$s = $components->[$i]->as_string;
			chomp $s;
			if ( $s ne q{} ) {
				$string .= $self->indent( 4, $s );
				$string .= "\n";
			}
		}

		# End the fragment.
		$string .= <<'EOF';
  </Fragment>
</Wix>
EOF
		return $string;
	} ## end sub as_string

}

1;
