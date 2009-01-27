package Perl::Dist::WiX::Files;

####################################################################
# Perl::Dist::WiX::Files - <Fragment> tag that contains 
# <DirectoryRef> tags 
#
# Copyright 2009 Curtis Jewell
#
# License is the same as perl. See Wix.pm for details.
#
# $Rev$ $Date$ $Author$
# $URL$

use 5.006;
use strict;
use warnings;
use Carp              qw( croak                         );
use Params::Util      qw( _IDENTIFIER _STRING _INSTANCE );
use Data::UUID        qw( NameSpace_DNS                 );
use File::Spec        qw();
require Perl::Dist::WiX::DirectoryTree;
require Perl::Dist::WiX::Base::Fragment;
require Perl::Dist::WiX::Files::DirectoryRef;

use vars qw{$VERSION @ISA};
BEGIN {
    $VERSION = '0.11_07';
    @ISA = 'Perl::Dist::WiX::Base::Fragment';
}

#####################################################################
# Accessors:
#   see new.

use Object::Tiny qw{ 
    directory_tree
    sitename
    trace
};

#####################################################################
# Constructor for Files
#
# Parameters: [pairs]
#   directory_tree: [Wix::DirectoryTree object] The initial directory tree.
#   sitename: The name of the site that is hosting the download.
#   trace: Enables debugging output.

sub new {
    my $self = shift->SUPER::new(@_);

    # Check parameters
    unless (_INSTANCE($self->directory_tree, 'Perl::Dist::WiX::DirectoryTree')) {
        croak('Missing or invalid directory_tree parameter');
    }
    unless ( _STRING($self->sitename) ) {
        croak('Missing or invalid sitename parameter - cannot generate GUID without one');
    }
    
    # Apply defaults
    if (not defined $self->{trace}) {
        $self->{trace} = 0;
    }

#     $self->{trace} = 1;
    
    return $self;
}

sub _print {
    my $self = shift;
    if ($self->trace) { print @_; }
    return $self;
}

########################################
# add_files(@files)
# Parameters:
#   @files: List of filenames to add.
# Returns:
#   Object being operated on (chainable).

sub add_files {
    my ($self, @files) = @_;
    
    # Each file could be a directory or have a newline, so fix that and add the files.
    foreach my $file (@files) {
        chomp $file;
        next if not -f $file;
        if (not defined $self->add_file($file)) {
            croak "Could not add $file";
        }
    }

    return $self;
}

########################################
# add_file($file)
# Parameters:
#   $file: Filename to add.
# Returns:
#   Files::Component object added or undef.

sub add_file {
    my ($self, $file) = @_;
    my $directory_obj;
    my $file_obj;
    
    # Get the file path.
    my ($vol, $dirs, $filename) = File::Spec->splitpath($file); 
    my $path = File::Spec->catpath($vol, $dirs);

    # Remove ending backslash.
    if (substr($path, -1) eq '\\') {
        $path = substr($path, 0, -1);
    }
    
# 1. Is there a DirectoryRef for this path?
    
    # Check if we have a DirectoryRef directly contained with the appropriate path.
    my $directory_ref = $self->_search_refs($path, 1);
    if (defined $directory_ref) {
        # Yes, we do. Add the file to this DirectoryRef.
        $self->_print("[Files " . __LINE__ . "] Stage 1 - Adding file to DirectoryRef for $path.\n");
        $self->_print("[Files " . __LINE__ . "]   Adding file $file.\n");
        $file_obj = $directory_ref->add_file(
            sitename => $self->sitename, 
            filename => $file,
        );
        return $file_obj;
    } else {
# 2. Is there another Directory to create a reference of?

        $self->_print("[Files " . __LINE__ . "] Stage 1 - Unsuccessful.\n");
        # Check if we have a Directory in the tree to take a reference of.
        $directory_obj = $self->directory_tree->search($path, $self->trace);        
        if (defined $directory_obj) {
            # Yes, we do. Make a DirectoryRef, and attach it.
            $self->_print("[Files " . __LINE__ . "] Stage 2 - Creating DirectoryRef for $path.\n");
            $directory_ref = Perl::Dist::WiX::Files::DirectoryRef->new(
                sitename => $self->sitename,
                directory_object => $directory_obj
            );
            $self->add_component($directory_ref);
            
            # Did we get the path that we needed?
            if ($directory_obj->path ne $path) {

                $self->_print("[Files " . __LINE__ . "]   Adding path $path.\n");
                $self->_print("[Files " . __LINE__ . "]   Adding file $file.\n");
                # Create the directory objects and add the file.
                $directory_obj = $directory_ref->add_directory_path($path);
                $file_obj = $directory_obj->add_file(
                    sitename => $self->sitename, 
                    filename => $file,
                );
                return $file_obj;
            } else {
            
                $self->_print("[Files " . __LINE__ . "]   Adding file $file.\n");
                # Add the file.
                $file_obj = $directory_ref->add_file(
                    sitename => $self->sitename, 
                    filename => $file,
                );
                return $file_obj;
            }
        }
    
# 3. Is there a DirectoryRef that's higher up in the directory tree?

        $self->_print("[Files " . __LINE__ . "] Stage 2 - Unsuccessful.\n");
        # Get paths for each level up in the tree.
        $directory_obj = undef;
        my @paths = $self->_get_possible_paths($vol, $dirs);
        foreach my $path_portion (@paths) {

            $self->_print("[Files " . __LINE__ . "] Stage 3 - Searching $path_portion.\n");
            # Is there a DirectoryRef that exists at this level?
            $directory_ref = $self->_search_refs($path_portion);
            if (defined $directory_ref) {

                $self->_print("[Files " . __LINE__ . "] Stage 3 - Found DirectoryRef for $path_portion.\n");
            
                # Do we already have the correct path in Directory objects?.
                $directory_obj = $directory_ref->search($path);
                if (not defined $directory_obj) {

                    $self->_print("[Files " . __LINE__ . "]   Adding path $path.\n");
                    # We don't, so add the Directory object(s) required to climb down.
                    $directory_obj = $directory_ref->add_directory_path($path);
                }

                $self->_print("[Files " . __LINE__ . "]   Adding file $file.\n");
                # Add the file, now that we have the Directory object we need.
                $file_obj = $directory_obj->add_file(
                    sitename => $self->sitename, 
                    filename => $file,
                );
                return $file_obj;
            }
        }
        
# 4. Search the tree, create a new DirectoryRef and add it to the list.

        $self->_print("[Files " . __LINE__ . "] Stage 3 - Unsuccessful.\n");
        # Put the full path back in the list of directories to search for.
        unshift @paths, $path;

        # Search until we find a directory object.
        foreach my $path_portion (@paths) {
        
            # Search the directory tree.
            $directory_obj = $self->directory_tree->search($path_portion);
            if (defined $directory_obj) {

                $self->_print("[Files " . __LINE__ . "] Stage 4 - Creating DirectoryRef for $path_portion.\n");
            
                # Make a DirectoryRef and attach it.
                $directory_ref = Perl::Dist::WiX::Files::DirectoryRef->new(
                    sitename => $self->sitename,
                    directory_object => $directory_obj
                );
                $self->add_component($directory_ref);

                # Did we add the file's directory?
                if ($path_portion ne $path) {

                    $self->_print("[Files " . __LINE__ . "]   Adding path $path.\n");
                    $self->_print("[Files " . __LINE__ . "]   Adding file $file.\n");
                    # Add required directories .
                    $directory_obj = $directory_ref->add_directory_path($path);
                    $file_obj = $directory_obj->add_file(
                        sitename => $self->sitename, 
                        filename => $file,
                        );
                    return $file_obj;
                } else {

                    $self->_print("[Files " . __LINE__ . "]   Adding file $file.\n");
                    # Add the file.
                    $file_obj = $directory_ref->add_file(
                        sitename => $self->sitename, 
                        filename => $file,
                    );
                    return $file_obj;
                }
            }
        }
    }
    
    $self->_print("[Files " . __LINE__ . "] Stage 4 - Unsuccessful.\n");
    # Completely unsuccessful.
    return undef;
}

# Gets a list of paths "above" the currect directory specified in
# $volume and $dirs.

sub _get_possible_paths {
    my ($self, $volume, $dirs) = @_;
    
    # Get our list of directories.
    my @directories = File::Spec->splitdir($dirs);

    # Get rid of empty entries at the beginning or end.
    while ($directories[-1] eq q{}) {
        pop @directories;
    }
    while ($directories[0] eq q{}) {
        shift @directories;
    }
    
    my $dir;
    my @answers;
    
    # Until we get to the last level...
    while ($#directories > 1) {
    
        # Remove a level and create its path.
        pop @directories;
        $dir = File::Spec->catfile($volume, File::Spec->catdir(@directories));
        
        # Add it to the answers list.
        push @answers, $dir;
    }
   
    return @answers;
}

# Searches our contained DirectoryRefs for a path.

sub _search_refs {
    my ($self, $path_to_find, $quick) = @_;

    my $answer = undef;
 
    # How many descendants do we have?
    my $count = scalar @{$self->{components}};

    # Pass the search down to each our descendants.
    foreach my $i (0 .. $count - 1) {
        $answer = $self->{components}->[$i]->search($path_to_find, $quick);

        # Exit if one of our descendants is successful.
        return $answer if defined $answer;
    }

    # We were unsuccessful.
    return undef;
}

########################################
# search_file($filename)
# Parameters:
#   $filename: Filename to search for.
# Returns:
#   Files::Component object found or undef.

sub search_file {
    my ($self, $filename) = @_;
    my $answer = undef;
 
    # How many descendants do we have?
    my $count = scalar @{$self->{components}};

    # Pass the search down to each our descendants.
    foreach my $i (0 .. $count - 1) {
        $answer = $self->{components}->[$i]->search_file($filename);

        # Exit if one of our descendants is successful.
        return $answer if defined $answer;
    }

    # We were unsuccessful.
    return undef;
}

########################################
# check_duplicates($files_ref)
# Parameters:
#   $files_ref: arrayref of filenames to remove from this object.
# Returns:
#   Object being operated on (chainable).
# Action:
#   Removes filenames listed in $files_ref from this object if they're in it.

sub check_duplicates {
    my ($self, $files_ref) = @_;
    my $answer;
    my ($object, $index);

    # Search out duplicate filenames and delete them if found.
    foreach my $file (@{$files_ref}) {
        $answer = $self->search_file($file);
        if (defined $answer) {
            ($object, $index) = @{$answer};
            $object->delete_filenum($index);
        }
    }
    
    return $self;
}

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
    my $count = scalar @{$self->{components}};
    foreach my $i (0 .. $count - 1) {
        push @answer, $self->{components}->[$i]->get_component_array;
    }
    
    return @answer;
}

########################################
# as_string
# Parameters:
#   None.
# Returns:
#   String containing fragment defined by this object
#   and DirectoryRef objects contained in this object.

sub as_string {
    my $self = shift;
    my ($string, $s);

    # How many descendants do we have?
    my $count = scalar @{$self->{components}};
    
    # Short circuit.
    if ($count == 0) {
        croak "*** No components in fragment $self->{id}";
        return q{}; 
    }

    # Start our fragment.
    $string = <<"EOF";
<?xml version='1.0' encoding='windows-1252'?>
<Wix xmlns='http://schemas.microsoft.com/wix/2006/wi'>
  <Fragment Id='Fr_$self->{id}'>
EOF

    # Get the string for each descendant.
    foreach my $i (0 .. $count - 1) {
        $s = $self->{components}->[$i]->as_string;
        chomp $s;
        if ($s ne q{}) {
            $string .= $self->indent(4, $s);
            $string .= "\n";
        }
    }
    
    # End the fragment.
    $string .= <<'EOF';
  </Fragment>
</Wix>
EOF
    return $string;
}

1;
