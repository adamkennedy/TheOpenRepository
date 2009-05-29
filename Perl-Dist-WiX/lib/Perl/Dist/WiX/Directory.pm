package Perl::Dist::WiX::Directory;

#####################################################################
# Perl::Dist::WiX::Files::Directory - Class for a <Directory> tag.
#
# Copyright 2009 Curtis Jewell
#
# License is the same as perl. See Wix.pm for details.
#
#<<<
use     5.008001;
use     strict;
use     warnings 'all' => 'FATAL';
use     vars                   qw( $VERSION           );
use     Object::InsideOut      qw( 
	Perl::Dist::WiX::Base::Component 
	Perl::Dist::WiX::Base::Entry
	Storable
);
use     Params::Util
  qw( _IDENTIFIER _STRING _NONNEGINT _HASH  );
use     Scalar::Util           qw( blessed            );
use     File::Spec::Functions  qw( catdir splitdir    );
require Perl::Dist::WiX::Files::Component;

use version; $VERSION = version->new('0.183')->numify;
#>>>
#####################################################################
# Accessors:
#   name, path, special: See constructor.

my @directories : Field : Name(directories);
my @files : Field : Name(files);

my @name : Field : Arg(name) : Get(get_name);
my @path : Field : Arg(path) : Get(get_path);
my @special : Field : Arg(special) : Get(get_special);

#####################################################################
# Constructor for Directory
#
# Parameters: [pairs]
#   name: The name of the directory to create.
#   path: The path to and including the directory on the local filesystem.
#   special: [integer] defaults to 0, 1 = Id should not be prefixed,
#     2 = directory without name

sub _init : Init {
	my $self      = shift;
	my $object_id = ${$self};

	# Check parameters.
	if ( not defined _NONNEGINT( $special[$object_id] ) ) {
		$special[$object_id] = 0;
	}
	if (   ( $special[$object_id] == 0 )
		&& ( not _STRING( $path[$object_id] ) ) )
	{
		PDWiX::Parameter->throw(
			parameter => 'path',
			where     => '::Directory->new'
		);
	}
	if (   ( not defined _STRING( $self->get_guid ) )
		&& ( not defined _STRING( $self->get_component_id ) ) )
	{
		$self->set_guid( $self->generate_guid( $path[$object_id] ) );
		my $id = $self->get_guid;
		$id =~ s{-}{_}msg;
		$self->set_component_id($id);
	}

	# Initialize arrayrefs.
	$directories[$object_id] = [];
	$files[$object_id]       = [];

	return $self;
} ## end sub _init :

#####################################################################
# Main Methods

########################################
# search_dir(path_to_find => $path, ...)
# Parameters: [pairs]
#   path_to_find: Path being searched for.
#   descend: 1 if can descend to lower levels, [default]
#            0 if has to be on this level.
#   exact:   1 if has to be equal,
#            0 if equal or subset. [default]
# Returns: [Directory object]
#   Directory object if this is the object for this directory OR
#   ( if a object contained in this object is AND descent = 1 AND exact = 1 ) OR
#   ( if there are no lower matching directories AND descent = 1 AND exact = 0)

sub search_dir {
	my $self       = shift;
	my $params_ref = {@_};
	my $object_id  = ${$self};
	my $path       = $path[$object_id];

	# Quick jump down the tree if we start at the head.
	if (    ( defined $name[$object_id] )
		and ( $name[$object_id] eq 'SourceDir' ) )
	{
		$self->trace_line( 4, "Passing search down from root.\n" );
		return $directories[$object_id]->[0]->search_dir(@_);
	}

	# Set defaults for parameters.
	my $path_to_find = _STRING( $params_ref->{path_to_find} )
	  || PDWiX::Parameter->throw(
		parameter => 'path_to_find',
		where     => '::Directory->search_dir'
	  );
	my $descend = $params_ref->{descend} || 1;
	my $exact   = $params_ref->{exact}   || 0;

	$self->trace_line( 3, "Looking for $path_to_find\n" );
	$self->trace_line( 4, "  in:      $path.\n" );
	$self->trace_line( 5, "  descend: $descend exact: $exact.\n" );

	# If we're at the correct path, exit with success!
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
	my $count = scalar @{ $directories[$object_id] };
	my $answer;
	$self->trace_line( 4, "Number of directories to search: $count\n" );
	foreach my $i ( 0 .. $count - 1 ) {
		$self->trace_line( 5, "Searching directory #$i in $path\n" );
		$answer =
		  $directories[$object_id]->[$i]->search_dir( %{$params_ref} );
		if ( defined $answer ) {
			return $answer;
		}
	}

	# If we get here, we did not find a lower directory.
	return $exact ? undef : $self;
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
	my $path      = $path[$object_id];

	# Check required parameters.
	unless ( _STRING($filename) ) {
		PDWiX::Parameter->throw(
			parameter => 'filename',
			where     => '::Directory->search_file'
		);
	}

	# Do we want to continue searching down this direction?
	my $subset = $filename =~ m/\A\Q$path\E/msx;
	return undef if not $subset;

	# Check each of our branches.
	my $count = scalar @{ $files[$object_id] };
	my $answer;
	foreach my $i ( 0 .. $count - 1 ) {
		next if ( not defined $files[$object_id]->[$i] );
		$answer = $files[$object_id]->[$i]->is_file($filename);
		if ($answer) {
			return [ $self, $i ];
		}
	}
	$count  = scalar @{ $directories[$object_id] };
	$answer = undef;
	foreach my $i ( 0 .. $count - 1 ) {
		$answer = $directories[$object_id]->[$i]->search_file($filename);
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
		PDWiX::Parameter->throw(
			parameter => 'index',
			where     => '::Directory->delete_filenum'
		);
	}

	$self->trace_line( 3,
		    'Deleting reference to '
		  . $files[$object_id]->[$i]->filename
		  . "\n" );
	$files[$object_id]->[$i] = undef;
	return $self;
} ## end sub delete_filenum

########################################
# add_directories_id(($id, $name)...)
# Parameters: [repeatable in pairs]
#   $id:   ID of directory object to create.
#   $name: Name of directory to create object for.
# Returns:
#   Object being operated on. (chainable)

sub add_directories_id {
	my ( $self, @params ) = @_;

	# We need id, name pairs passed in.
	if ( $#params % 2 != 1 )           # The test is weird, but $#params
	{                                  # is one less than the actual count.
		PDWiX->throw(
			'Internal Error: Odd number of parameters to add_directories_id'
		);
	}

	# Add each individual id and name.
	my ( $id, $name );
	while ( $#params > 0 ) {
		$id   = shift @params;
		$name = shift @params;
		if ( $name =~ m{\\}ms ) {
			$self->add_directory( {
					id   => $id,
					path => $name,
				} );
		} else {
			$self->add_directory( {
					id   => $id,
					path => $self->get_path . q{\\} . $name,
					name => $name,
				} );
		}
	} ## end while ( $#params > 0 )

	return $self;
} ## end sub add_directories_id

########################################
# add_directories_init(@dirs)
# Parameters:
#   @dirs: List of directories to create object for.
# Returns:
#   Object being operated on. (chainable)

sub add_directories_init {
	my ( $self, @params ) = @_;

	my $name;
	while ( $#params >= 0 ) {
		$name = shift @params;
		next if not defined $name;
		if ( substr( $name, -1 ) eq q{\\} ) {
			$name = substr $name, 0, -1;
		}
		$self->add_directory(
			{ path => $self->get_path . q{\\} . $name, } );
	}

	return $self;
} ## end sub add_directories_init

########################################
# add_directory_path($path)
# Parameters:
#   @path: Path of directories to create object(s) for.
# Returns:
#   Directory object created.

sub add_directory_path {
	my ( $self, $path ) = @_;
	my $object_id = ${$self};

	# Check required parameters.
	unless ( _STRING($path) ) {
		PDWiX::Parameter->throw(
			parameter => 'path',
			where     => '::Directory->add_directory_path'
		);
	}

	if ( substr( $path, -1 ) eq q{\\} ) {
		$path = substr $path, 0, -1;
	}

	my $path_to_remove = $path[$object_id];
	if ( not( $path =~ m{\A\Q$path_to_remove\E}msx ) ) {
		$self->trace_line( 0,
			"Path to add: $path\nPath to add to: $path_to_remove\n" );
		PDWiX->throw(q{Can't add the directories required});
	}

	# Get list of directories to add.
	$path =~ s{\A\Q$path_to_remove\E\\}{}msx;
	my @dirs = File::Spec->splitdir($path);

	# Get rid of empty entries at the beginning.
	while ( $dirs[-1] eq q{} ) {
		pop @dirs;
	}

	my $directory_obj = $self;
	my $path_create   = $path[$object_id];
	my $name_create;
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
# add_directory($params_ref)
# Parameters: [hashref in $params_ref]
#   see new.
# Returns:
#   Directory object created.

sub add_directory {
	my ( $self, $params_ref ) = @_;
	my $object_id = ${$self};

	# Check parameters.
	unless ( _HASH($params_ref) ) {
		PDWiX->throw(
			'Internal Error: Parameters not passed in hash reference');
	}

	# Check required parameters.
	if ( (     ( not defined $params_ref->{special} )
			or ( $params_ref->{special} == 0 ) )
		and ( not _STRING( $params_ref->{path} ) ) )
	{
		PDWiX::Parameter->throw(
			parameter => 'path',
			where     => '::Directory::add_directory'
		);
	}

	# If we have a name or a special code, we create it under here.
	if (   ( defined $params_ref->{name} )
		|| ( defined $params_ref->{special} ) )
	{
		defined $params_ref->{name}
		  ? $self->trace_line( 4, "Adding directory $params_ref->{name}\n" )
		  : $self->trace_line( 4,
			"Adding directory Id $params_ref->{id}\n" );
		my $i = scalar @{ $directories[$object_id] };
		$directories[$object_id]->[$i] =
		  Perl::Dist::WiX::Directory->new( %{$params_ref} );
		return $directories[$object_id]->[$i];
	} else {
		$self->trace_line( 4, "Adding $params_ref->{path}\n" );
		my $path = $params_ref->{path};

		# Find the directory object where we want to create this directory.
		my ( $volume, $directories, undef ) =
		  File::Spec->splitpath( $path, 1 );
		my @dirs = splitdir($directories);
		my $name = pop @dirs;          # to eliminate the last directory.
		$directories = catdir(@dirs);
		my $directory = $self->search_dir(
			path_to_find => catdir( $volume, $directories ),
			descend      => 1,
			exact        => 1,
		);

		if ( not defined $directory ) {
			PDWiX->throw( q{Can't create intermediate directories }
				  . "when creating $path (unsuccessful search for "
				  . "$volume$directories)" );
		}

		# Add the directory there.
		$params_ref->{name} = $name;
		$directory->add_directory($params_ref);
		return $directory;
	} ## end else [ if ( ( defined $params_ref...
} ## end sub add_directory

########################################
# is_child_of($directory_obj)
# Parameters:
#   $directory_obj [WiX::Directory object]:
#     Directory object to compare against.
# Returns:
#   0 if a 'special' or we are not a child
#     of the directory passed in.
#   1 otherwise.

sub is_child_of {
	my ( $self, $directory_object ) = @_;

	# Check for a valid Directory or DirectoryRef object.
	my $class = blessed($directory_object);
	unless (
		defined $class
		and (  ( $class eq 'Perl::Dist::WiX::Directory' )
			or ( $class eq 'Perl::Dist::WiX::Files::DirectoryRef' ) ) )
	{
		PDWiX::Parameter->throw( 'directory_object',
			where => '::Directory->is_child_of' );
	}

	my $path_to_check = $directory_object->get_path;
	my $path          = $self->get_path;
	if ( not defined $path_to_check ) {
		$self->trace_line( 5,
			"Is Child Of: Answer: No path detected (0)\n" );
		return 0;
	}

	# Short-circuit.
	if ( $path eq $path_to_check ) {
		$self->trace_line( 5, "Is Child Of: Answer: Identity (0)\n" );
		return 0;
	}

	my $answer = "$path\\" =~ m{\A\Q$path_to_check\E\\}msx ? 1 : 0;
	$self->trace_line( 5,
		    "Is Child Of: Answer: $answer\n  "
		  . "Path: $path\n  Path to check: $path_to_check\n" );
	return $answer;
} ## end sub is_child_of

########################################
# add_file(...)
# Parameters: [pairs]
#   See Files::Component->new.
# Returns:
#   Files::Component object created.

sub add_file {
	my ( $self, @params ) = @_;
	my $object_id = ${$self};

	my $i = scalar @{ $files[$object_id] };
	$files[$object_id]->[$i] =
	  Perl::Dist::WiX::Files::Component->new(@params);
	return $files[$object_id]->[$i];
}


########################################
# get_component_array
# Parameters:
#   None
# Returns:
#   Array of Ids attached to the contained directory and file objects.

sub get_component_array {
	my $self      = shift;
	my $object_id = ${$self};

	my $count = scalar @{ $directories[$object_id] };
	my @answer;
	my $id;

	# Get the array for each descendant.
	foreach my $i ( 0 .. $count - 1 ) {
		push @answer, $directories[$object_id]->[$i]->get_component_array;
	}

	$count = scalar @{ $files[$object_id] };
	foreach my $i ( 0 .. $count - 1 ) {
		next if ( not defined $files[$object_id]->[$i] );
		push @answer, $files[$object_id]->[$i]->get_component_id;
	}

	return @answer;
} ## end sub get_component_array

########################################
# as_string
# Parameters:
#   $tree: 1 if printing directory tree. [i.e. DO print empty directories.]
# Returns:
#   String representation of the <Directory> tag represented
#   by this object, and the <Directory> and <File> tags
#   contained in it.

sub as_string {
	my ( $self, $tree ) = @_;
	my $object_id = ${$self};
	my ( $count, $answer );
	my $string = q{};
	if ( not defined $tree ) { $tree = 0; }

	# Get string for each subdirectory.
	$count = scalar @{ $directories[$object_id] };
	foreach my $i ( 0 .. $count - 1 ) {
		$string .= $directories[$object_id]->[$i]->as_string($tree);
	}

	# Get string for each file this directory contains.
	$count = scalar @{ $files[$object_id] };
	foreach my $i ( 0 .. $count - 1 ) {
		next if ( not defined $files[$object_id]->[$i] );
		$string .= $files[$object_id]->[$i]->as_string;
	}

	# Short circuits...
	if (    ( $string eq q{} )
		and ( $special[$object_id] == 0 )
		and ( $tree == 0 ) )
	{
		return q{};
	}
	my $id = $self->get_component_id();
	if ( ( $string eq q{} ) and ( $id eq 'TARGETDIR' ) ) {
		return q{};
	}

	# Now make our own string, and put what we've already got within it.
	my $name = $name[$object_id];
	if ( ( defined $string ) && ( $string ne q{} ) ) {
		if ( $special[$object_id] == 2 ) {
			$answer = "<Directory Id='$id'>\n";
			$answer .= $self->indent( 2, $string );
			$answer .= "\n</Directory>\n";
		} elsif ( $id eq 'TARGETDIR' ) {
			$answer = "<Directory Id='$id' Name='$name'>\n";
			$answer .= $self->indent( 2, $string );
			$answer .= "\n</Directory>\n";
		} else {
			$answer = "<Directory Id='D_$id' Name='$name'>\n";
			$answer .= $self->indent( 2, $string );
			$answer .= "\n</Directory>\n";
		}
	} else {
		if ( $special[$object_id] == 2 ) {
			$answer = "<Directory Id='$id' />\n";
		} else {
			$answer = "<Directory Id='D_$id' Name='$name' />\n";
		}
	}

	return $answer;
} ## end sub as_string

1;
