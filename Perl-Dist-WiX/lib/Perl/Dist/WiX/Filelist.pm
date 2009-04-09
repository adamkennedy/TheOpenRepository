package Perl::Dist::WiX::Filelist;

####################################################################
# Perl::Dist::WiX::Filelist - This package provides for handling
# files lists for Perl::Dist::WiX.
#
# Copyright 2009 Curtis Jewell
#
# License is the same as perl. See Wix.pm for details.
#
#<<<
use 5.006;
use strict;
use warnings;
use vars                   qw( $VERSION                          );
use Object::InsideOut      qw( Perl::Dist::WiX::Misc Storable    );
use File::Spec::Functions  qw( catdir catfile splitpath splitdir );
use Params::Util           qw( _INSTANCE _STRING _NONNEGINT      );
use IO::Dir                qw();
use IO::File               qw();

use version; $VERSION = version->new('0.169')->numify;

my %sortcache; # Defined at this level so that the cache does not
			   # get reset each time _sorter is called.

#>>>
#####################################################################
# Accessors:
#   none.

my @files : Field : Name(files) : Get(Name => 'get_files', Private => 1);

#####################################################################
# Constructors for Filelist
#

########################################
# new
# Parameters:
#   None.

sub _init : Init {
	my $self      = shift;
	my $object_id = ${$self};

	# Initialize files area.
	$files[$object_id] = {};

	return $self;
}

########################################
# clone
# Parameters:
#   $source: [Filelist object] Object to copy.

sub clone {
	my $self      = shift->new();
	my $object_id = ${$self};
	my $source    = shift;

	# Check parameters
	unless ( _INSTANCE( $source, 'Perl::Dist::WiX::Filelist' ) ) {
		PDWiX::Parameter->throw(
			parameter => 'source',
			where     => '::Filelist->clone'
		);
	}

	my %files = %{ $source->get_files };

	# Add filelist passed in.
	$files[$object_id] = \%files;

	return $self;
} ## end sub clone

#####################################################################
# Main Methods

sub _splitdir {
	my $dirs = shift;

	my @dirs = splitdir($dirs);

	@dirs = grep { defined $_ and $_ ne q{} } @dirs;

	return \@dirs;
}

sub _splitpath {
	my $path = shift;

	my @answer = splitpath( $path, 0 );

	return \@answer;
}

sub _sorter {

# Takes advantage of $a and $b, using the Orcish Manoevure to cache
# calls to File::Spec::Functions::splitpath and splitdir

	# Short-circuit.
	return 0 if ( $a eq $b );

	# Get directoryspec and file
	my ( undef, $dirspec_1, $file_1 ) =
	  @{ ( $sortcache{$a} ||= _splitpath($a) ) };
	my ( undef, $dirspec_2, $file_2 ) =
	  @{ ( $sortcache{$b} ||= _splitpath($b) ) };

	# Deal with equal directories by comparing their files.
	return ( $file_1 cmp $file_2 ) if ( $dirspec_1 eq $dirspec_2 );

	# Get list of directories.
	my @dirs_1 = @{ ( $sortcache{$dirspec_1} ||= _splitdir($dirspec_1) ) };
	my @dirs_2 = @{ ( $sortcache{$dirspec_2} ||= _splitdir($dirspec_2) ) };

	# Find first directory that is not equal.
	my ( $dir_1, $dir_2 ) = ( q{}, q{} );
	while ( $dir_1 eq $dir_2 ) {
		$dir_1 = shift @dirs_1 || q{};
		$dir_2 = shift @dirs_2 || q{};
	}

	# Compare directories/
	return 1  if $dir_1 eq q{};
	return -1 if $dir_2 eq q{};
	return $dir_1 cmp $dir_2;
} ## end sub _sorter


########################################
# files
# Parameters:
#   None.
# Returns:
#   Sorted list of files in this object

sub files {
	my $self      = shift;
	my $object_id = ${$self};

	my @answer = sort {_sorter} keys %{ $files[$object_id] };
	return \@answer;
}


########################################
# count
# Parameters:
#   None.
# Returns:
#   Number of files in this object

sub count {
	my $self      = shift;
	my $object_id = ${$self};
	return scalar keys %{ $files[$object_id] };
}

########################################
# clear
# Parameters:
#   None.
# Returns:
#   Object being acted upon (chainable)
# Action:
#   Clears this filelist.

sub clear {
	my $self      = shift;
	my $object_id = ${$self};

	delete $files[$object_id];
	$files[$object_id] = {};

	return $self;
}

########################################
# readdir($dir)
# Parameters:
#   $dir: Directory containing a files and subdirectories to add to this filelist.
# Returns:
#   Object being acted upon (chainable)
# Action:
#   Adds the files in $dir to our filelist.

sub readdir { ## no critic 'ProhibitBuiltinHomonyms'
	my ( $self, $dir ) = @_;
	my $object_id = ${$self};

	# Check parameters.
	unless ( _STRING($dir) ) {
		PDWiX::Parameter->throw(
			parameter => 'dir',
			where     => '::Filelist->readdir'
		);
	}
	unless ( -d $dir ) {
		PDWiX::Parameter->throw(
			parameter => "dir: $dir is not a directory",
			where     => '::Filelist->readdir'
		);
	}

	# Open directory.
	my $dir_object = IO::Dir->new($dir);
	if ( !defined $dir_object ) {
		PDWiX->throw("Error reading directory $dir: $!");
	}

	# Read a file from the directory.
	my $file = $dir_object->read();

	while ( defined $file ) {

		# Check to make sure it isn't . or ..
		if ( ( $file ne q{.} ) and ( $file ne q{..} ) ) {

			# Check for another directory.
			my $filespec = catfile( $dir, $file );
			if ( -d $filespec ) {

				# Read this directory.
				$self->readdir($filespec);
			} else {

				# Add the file!
				$files[$object_id]{$filespec} = 1;
			}
		} ## end if ( ( $file ne q{.} )...

		# Next one, please?
		$file = $dir_object->read();
	} ## end while ( defined $file )

	return $self;
} ## end sub readdir

########################################
# load_file($packlist)
# Parameters:
#   $packlist: File containing a list of files to add to this filelist.
# Returns:
#   Object being acted upon (chainable)
# Action:
#   Adds the files listed in the file in $packlist to our filelist.

sub load_file {
	my ( $self, $packlist ) = @_;
	my $object_id = ${$self};

	# Check parameters.
	unless ( _STRING($packlist) ) {
		PDWiX::Parameter->throw(
			parameter => 'packlist',
			where     => '::Filelist->load_file'
		);
	}
	unless ( -r $packlist ) {
		PDWiX::Parameter->throw(
			parameter => "packlist: $packlist cannot be read",
			where     => '::Filelist->load_file'
		);
	}

	# Read ,packlist file.
	my $fh = IO::File->new( $packlist, 'r' );
	if ( not defined $fh ) {
		PDWiX->throw("Error reading packlist file $packlist: $!");
	}
	my @files_list = <$fh>;
	$fh->close;
	my $file;

	# Insert list of files read into this object. Chomp on the way.
	my %files = map { ## no critic 'ProhibitComplexMappings'
		$file = $_;
		chomp $file;
		( $file, 1 );
	} @files_list;
	$files[$object_id] = \%files;

	return $self;
} ## end sub load_file

########################################
# load_array(@files_list)
# Parameters:
#   @files_list: Files to add to this filelist.
# Returns:
#   Object being acted upon (chainable)
# Action:
#   Adds the files listed in @files to our filelist.

sub load_array {
	my ( $self, @files_list ) = @_;
	my $object_id = ${$self};

	# Add each file in the array - if it is a file.
	foreach my $file (@files_list) {
		next if not -f $file;
		$files[$object_id]{$file} = 1;
	}

	return $self;
} ## end sub load_array

########################################
# add_file($file)
# Parameters:
#   $file: File to add to this filelist.
# Returns:
#   Object being acted upon (chainable)
# Action:
#   Adds the file listed in $file to our filelist.

sub add_file {
	my ( $self, $file ) = @_;
	my $object_id = ${$self};

	# Check parameters.
	unless ( _STRING($file) ) {
		PDWiX::Parameter->throw(
			parameter => 'file',
			where     => '::Filelist->add_file'
		);
	}

	$files[$object_id]{$file} = 1;

	return $self;
} ## end sub add_file

########################################
# subtract($subtrahend)
# Parameters:
#   $subtrahend: [Filelist object] A filelist to remove from this one.
# Returns:
#   Object being acted upon (chainable)
# Action:
#   Removes the files listed in $subtrahend from our filelist.

sub subtract {
	my ( $self, $subtrahend ) = @_;
	my $object_id = ${$self};

	# Check parameters
	unless ( _INSTANCE( $subtrahend, 'Perl::Dist::WiX::Filelist' ) ) {
		PDWiX::Parameter->throw(
			parameter => 'subtrahend',
			where     => '::Filelist->subtract'
		);
	}

	my @files_to_remove = keys %{ $subtrahend->get_files };
	delete @{ $files[$object_id] }{@files_to_remove};

	return $self;
} ## end sub subtract

########################################
# add($term)
# Parameters:
#   $term: [Filelist object] A filelist to add to this one.
# Returns:
#   Object being acted upon (chainable)
# Action:
#   Adds the files listed in $term to our filelist.

sub add {
	my ( $self, $term ) = @_;
	my $object_id = ${$self};

	# Check parameters
	unless ( _INSTANCE( $term, 'Perl::Dist::WiX::Filelist' ) ) {
		PDWiX::Parameter->throw(
			parameter => 'term',
			where     => '::Filelist->add'
		);
	}

	# Add the two hashes together.
	my %files = ( %{ $files[$object_id] }, %{ $term->get_files } );
	$files[$object_id] = \%files;

	return $self;
} ## end sub add

########################################
# move($from, $to)
# Parameters:
#   $from: the file or directory that has been moved on disk.
#   $to: The location being moved to.
# Returns:
#   Object being acted upon (chainable)
# Action:
#   Substitutes $to for $from in the filelist.

sub move {
	my ( $self, $from, $to ) = @_;
	my $object_id = ${$self};

	# Check parameters.
	unless ( _STRING($from) ) {
		PDWiX::Parameter->throw(
			parameter => 'from',
			where     => '::Filelist->move'
		);
	}
	unless ( _STRING($to) ) {
		PDWiX::Parameter->throw(
			parameter => 'to',
			where     => '::Filelist->move'
		);
	}

	# Move the file if it exists.
	if ( $files[$object_id]{$from} ) {
		delete $files[$object_id]{$from};
		$files[$object_id]{$to} = 1;
	}

	return $self;
} ## end sub move

########################################
# move_dir($from, $to)
# Parameters:
#   $from: the file or directory that has been moved on disk.
#   $to: The location being moved to.
# Returns:
#   Object being acted upon (chainable)
# Action:
#   Substitutes $to for $from in the filelist.

sub move_dir {
	my ( $self, $from, $to ) = @_;
	my $object_id = ${$self};

	# Check parameters.
	unless ( _STRING($from) ) {
		PDWiX::Parameter->throw(
			parameter => 'from',
			where     => '::Filelist->move_dir'
		);
	}
	unless ( _STRING($to) ) {
		PDWiX::Parameter->throw(
			parameter => 'to',
			where     => '::Filelist->move_dir'
		);
	}

	# Find which files need moved.
	my @files_to_move =
	  grep { "$_\\" =~ m{\A\Q$from\E\\}msx }
	  keys %{ $files[$object_id] };
	my $to_file;
	foreach my $file_to_move (@files_to_move) {

		# Get the correct name.
		$to_file = $file_to_move;
		$to_file =~ s{\A\Q$from\E}{$to}msx;

		# "move" the file.
		delete $files[$object_id]{$file_to_move};
		$files[$object_id]{$to_file} = 1;
	}

	return $self;
} ## end sub move_dir


########################################
# filter($re_list)
# Parameters:
#   $re_list: Arrayref of strings to use as regular
#     expressions of filenames to filter out.
# Returns:
#   Object being acted upon (chainable)
# Action:
#   Removes files satisfying the filters in @re_list
#   from the object.

sub filter {
	my ( $self, $re_list ) = @_;
	my $object_id = ${$self};

	# Define variables to use.
	my @files_list = keys %{ $files[$object_id] };

	my @files_to_remove;

	# Filtering out values that match the regular expressions.
	foreach my $re ( @{$re_list} ) {
		$self->trace_line( 4, "Filtering on $re\n" );
		push @files_to_remove, grep {m/\A\Q$re\E/msx} @files_list;
	}

	delete @{ $files[$object_id] }{@files_to_remove};

	return $self;
} ## end sub filter

########################################
# as_string
# Parameters:
#   None.
# Returns:
#   List of filenames in this object joined
#   by newlines for debugging purposes.

sub as_string {
	my $self      = shift;
	my $object_id = ${$self};

	my @files_list = sort {_sorter} keys %{ $files[$object_id] };

	return join "\n", @files_list;
}

1;
