package Perl::Dist::WiX::Files::DirectoryRef;
{
#####################################################################
# Perl::Dist::WiX::Files::DirectoryRef - Class for a <DirectoryRef> tag.
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
    Perl::Dist::WiX::Base::Component
    Perl::Dist::WiX::Base::Entry
    Storable
);
use Carp              qw( croak                                    );
use Params::Util      qw( _IDENTIFIER _STRING _INSTANCE _NONNEGINT );

use version; $VERSION = qv('0.13_02');
#>>>
#####################################################################
# Accessors:
#   directory_object: Returns the directory object passed in by new.

	my @directory_object : Field :
	  Arg(Name => 'directory_object', Required => 1) :
	  Get(directory_object);
	my @directories : Field;
	my @files : Field;

#####################################################################
# Constructor for Files::DirectoryRef
#
# Parameters: [pairs]
#   directory_object: The ::WiX::Directory object being referred to.

	sub _init : Init {
		my $self      = shift;
		my $object_id = ${$self};

		if (
			not _INSTANCE(
				$self->directory_object, 'Perl::Dist::WiX::Directory'
			) )
		{
			croak 'Missing or invalid directory object';
		}

		$directories[$object_id] = [];
		$files[$object_id]       = [];

		return $self;
	} ## end sub _init :


#####################################################################
# Main Methods

########################################
# get_path
# Parameters:
#   None.
# Returns:
#   Path of the directory object being referenced.

	sub get_path {
		my $object_id = ${
			do { shift; }
		  };
		return $directory_object[$object_id]->get_path;
	}

########################################
# search_dir(path_to_find => $path)
# Parameters: [pairs]
#   path_to_find: Path being searched for.
#   descend: 1 if can descend to lower levels, [default]
#            0 if has to be on this level.
#   exact:   1 if has to be equal,
#            0 if equal or subset. [default]
# Returns:
#   WiX::Files::DirectoryRef or WiX::Directory object representing
#   the path being searched for if successful.
#   undef if unsuccessful.

	sub search_dir {
		my $self       = shift;
		my $object_id  = ${$self};
		my $params_ref = {@_};

		# Set defaults for parameters.
		my $path_to_find = _STRING( $params_ref->{path_to_find} )
		  or croak 'No path to find.';
		my $descend = $params_ref->{descend} or 1;
		my $exact   = $params_ref->{exact}   or 0;

		# Get OUR path.
		my $path = $directory_object[$object_id]->get_path;

		$self->trace_line( 3, "Looking for $path_to_find\n" );
		$self->trace_line( 4, "  in: $path.\n" );
		$self->trace_line( 5, "  descend: $descend.  exact:   $exact.\n" );

		# Success!
		if ( ( defined $path ) && ( $path_to_find eq $path ) ) {
			$self->trace_line( 4, "Found $path.\n" );
			return $self;
		}

		# Quick exit if required.
		if ( not $descend ) {
			return undef;
		}

		# Do we want to continue searching down this direction?
		my $subset = "$path_to_find\\" =~ m{\A\Q$path\E\\}msx;
		if ( not $subset ) {
			$self->trace_line( 4, "Not a subset in: $path.\n" );
			$self->trace_line( 5, "  To find: $path_to_find.\n" );
			return undef;
		}

		# Check each of our branches.
		my $count  = scalar @{ $directories[$object_id] };
		my $answer = undef;
		foreach my $i ( 0 .. $count - 1 ) {
			$answer =
			  $directories[$object_id]->[$i]->search_dir( %{$params_ref} );
			if ( defined $answer ) {
				return $answer;
			}
		}

# If we get here, we did not find a directory, and we're the last subset if applicable.
		if ( not $exact ) {
			$self->trace_line( 5, "Found $path as subset.\n" );
			return $self;
		} else {
			return undef;
		}
	} ## end sub search_dir

########################################
# search_file($filename)
# Parameters:
#   $filename: File being searched for
# Returns: [arrayref]
#   [0] WiX::Files::DirectoryRef or WiX::Directory object representing
#       the path containing the file being searched for.
#   [1] The index of that file within the object returned in [0].
#   undef if unsuccessful.

	sub search_file {
		my ( $self, $filename ) = @_;
		my $object_id = ${$self};

		# Check parameters
		if ( not _STRING($filename) ) {
			croak 'Missing or invalid filename parameter';
		}

		# Get OUR path.
		my $path = $directory_object[$object_id]->get_path;

		# Do we want to continue searching down this direction?
		my $subset = ( "$filename\\" =~ m{\A\Q$path\E\\}msx ) ? 1 : 0;
		return undef if not $subset;

		# Check each file we contain.
		my $count = scalar @{ $files[$object_id] };
		my $answer;
		foreach my $i ( 0 .. $count - 1 ) {
			next if ( not defined $files[$object_id]->[$i] );
			$answer = $files[$object_id]->[$i]->is_file($filename);
			if ( $answer == 1 ) {
				return [ $self, $i ];
			}
		}

		# Check each of our branches.
		$count  = scalar @{ $directories[$object_id] };
		$answer = undef;
		foreach my $i ( 0 .. $count - 1 ) {
			$answer =
			  $directories[$object_id]->[$i]->search_file($filename);
			if ( defined $answer ) {
				return $answer;
			}
		}

		return undef;
	} ## end sub search_file

########################################
# delete_filenum($i)
# Parameters:
#   $i: Index of file to delete
# Returns:
#   Object being operated on. (chainable)

	sub delete_filenum {
		my ( $self, $i ) = @_;
		my $object_id = ${$self};

		# Check parameters
		if ( not defined _NONNEGINT($i) ) {
			croak 'Missing or invalid index parameter';
		}

		if ( $i >= scalar @{ $files[$object_id] } ) {
			croak 'Not enough files';
		}

		if ( not defined $files[$object_id]->[$i] ) {
			croak 'Already deleted this file';
		}

# Delete the file. (The object should disappear once its reference is set to undef)
		$self->trace_line( 3,
			    'Deleting reference to '
			  . $files[$object_id]->[$i]->filename
			  . "\n" );
		$files[$object_id]->[$i] = undef;

		return $self;
	} ## end sub delete_filenum

########################################
# add_directory({path => ?, name => ?})
# Parameters: [pairs within hashref]
#   path: Path of directory to create.
#   name: Name of directory to create.
# Returns:
#   True if this is the object for this filename.

	sub add_directory {
		my ( $self, $params_ref ) = @_;
		my $object_id = ${$self};

		# Check parameters
		if ( not _STRING( $params_ref->{path} ) ) {
			croak 'Missing or invalid path parameter';
		}

		# If we have a name, we create the directory object under here.
		if ( defined $params_ref->{name} ) {

			# Create our WiX::Directory object and attach and return it.
			my $i = scalar @{ $directories[$object_id] };
			$directories[$object_id]->[$i] =
			  Perl::Dist::WiX::Directory->new(
				path => $params_ref->{path},
				name => $params_ref->{name},
			  );
			return $directories[$object_id]->[$i];
		} else {

			# Catchable error condition.
			croak q{Can't create intermediate directories.};
		}
	} ## end sub add_directory

########################################
# is_child_of($directory_object)
# Parameters:
#   $directory_object: Directory object to compare to.
# Returns: [boolean]
#   True if we are a child of the directory object passed in.

	sub is_child_of {
		my ( $self, $directory_obj ) = @_;
		my $object_id = ${$self};

		# Check for a valid Directory or DirectoryRef object.
		unless (
			_INSTANCE( $directory_obj, 'Perl::Dist::WiX::Directory' )
			or _INSTANCE(
				$directory_obj, 'Perl::Dist::WiX::Files::DirectoryRef'
			) )
		{
			croak('Invalid directory object passed in.');
		}

		my $path_to_check = $directory_obj->path;
		my $path          = $directories[$object_id]->path;

		# Returns false if the object is a "special".
		if ( not defined $path_to_check ) {
			return 0;
		}

		# Short-circuit.
		if ( $path eq $path_to_check ) {
			$self->trace_line( 5, "Is Child Of: Answer: Identity (0)\n" );
			return 0;
		}

		# Do the check.
		my $answer = "$path\\" =~ m{\A\Q$path_to_check\E\\}msx ? 1 : 0;
		$self->trace_line( 5,
"Is Child Of: Answer: $answer\n  Path: $path\n  Path to check: $path_to_check\n"
		);
		return $answer;
	} ## end sub is_child_of

########################################
# add_file(...)
# Parameters:
#   See WiX::Files::Component->new.
# Returns:
#   The WiX::Files::Component object added.

	sub add_file {
		my ( $self, @params ) = @_;
		my $object_id = ${$self};

		# Check parameters
		if ( 0 == scalar @params ) {
			croak 'Missing file parameter';
		}

		foreach my $j ( 0 .. scalar @params - 1 ) {
			if ( not _STRING( $params[$j] ) ) {
				croak "Missing or invalid file[$j] parameter";
			}
		}

		# Where are we going to add the file?
		my $i = scalar @{ $files[$object_id] };

		# Create the file component and return it.
		$files[$object_id]->[$i] =
		  Perl::Dist::WiX::Files::Component->new(@params);
		return $files[$object_id]->[$i];
	} ## end sub add_file

########################################
# add_directory_path($path)
# Parameters:
#   $path: The directory path to add.
# Returns:
#   The last WiX::Directory object added.

	sub add_directory_path {
		my ( $self, $path ) = @_;
		my $object_id = ${$self};

		# Check parameters
		if ( not _STRING($path) ) {
			croak 'Missing or invalid path parameter';
		}

		# Make sure we don't have a trailing slash.
		if ( substr( $path, -1 ) eq q{\\} ) {
			$path = substr $path, 0, -1;
		}

		# Croak if we can't create this path under us.
		my $path_to_remove = $directory_object[$object_id]->get_path;
		if ( !( $path =~ m{\A\Q$path_to_remove\E}msx ) ) {
			$self->trace_line( 0,
				"Path to add: $path\nPath to add to: $path_to_remove\n" );
			croak q{Can't add the directories required};
		}

		# Get list of directories to add.
		$path =~ s{\A\Q$path_to_remove\E\\}{}msx;
		my @dirs = File::Spec->splitdir($path);

		# Get rid of empty entries at the beginning.
		while ( $dirs[-1] eq q{} ) {
			pop @dirs;
		}

		# Set up the loop.
		my $directory_obj = $self;
		my $path_create   = $directory_object[$object_id]->get_path;
		my $name_create;

		# Loop and create directory objects required.
		while ( $#dirs != -1 ) {
			$name_create = shift @dirs;
			$path_create = File::Spec->catdir( $path_create, $name_create );

			$directory_obj = $directory_obj->add_directory( {
					name => $name_create,
					path => $path_create,
				} );
		}

		return $directory_obj;
	} ## end sub add_directory_path

########################################
# get_component_array
# Parameters:
#   None
# Returns:
#   The Id attributes of all the components contained within this object.

	sub get_component_array {
		my $self      = shift;
		my $object_id = ${$self};
		my @answer;

		# Get the array for each descendant.
		my $count = scalar @{ $directories[$object_id] };
		foreach my $i ( 0 .. $count - 1 ) {
			push @answer,
			  $directories[$object_id]->[$i]->get_component_array;
		}

		# Get the Id entries for Files::Component entries we own.
		$count = scalar @{ $files[$object_id] };
		foreach my $i ( 0 .. $count - 1 ) {
			next if ( not defined $files[$object_id]->[$i] );
			push @answer, $files[$object_id]->[$i]->id;
		}

		return @answer;
	} ## end sub get_component_array

########################################
# as_string
# Parameters:
#   None
# Returns:
#   String representation of <DirectoryRef> tag represented by this object,
#   along with the <Component> and <Directory> entries it contains.

	sub as_string {
		my $self      = shift;
		my $object_id = ${$self};
		my ( $count, $answer, $string );

		# Get our own Id and print it.
		my $id = $directory_object[$object_id]->get_componment_id;
		$answer = "<DirectoryRef Id='D_$id'>\n";

		# Stringify the WiX::Directory objects we own.
		$count = scalar @{ $directories[$object_id] };
		foreach my $i ( 0 .. $count - 1 ) {
			$string .= $directories[$object_id]->[$i]->as_string;
		}

		# Stringify the WiX::Files::Component objects we own.
		$count = scalar @{ $files[$object_id] };
		foreach my $i ( 0 .. $count - 1 ) {
			next if ( not defined $files[$object_id]->[$i] );
			$string .= $files[$object_id]->[$i]->as_string;
		}

		if ( ( not defined $string ) or ( $string eq q{} ) ) {
			return q{};
		}

		# Finish up.
		$answer .= $self->indent( 2, $string );
		$answer .= "\n</DirectoryRef>\n";

		return $answer;
	} ## end sub as_string
}
1;
