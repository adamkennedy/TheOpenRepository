package Perl::Dist::WiX::Files;

####################################################################
# Perl::Dist::WiX::Files -  
#
# Copyright 2009 Curtis Jewell
#
# License is the same as perl. See Wix.pm for details.

=pod

=head1 NAME

Perl::Dist::WiX::Files - <Fragment> tag that contains <DirectoryRef> tags

=head1 DESCRIPTION

This class represents a <Fragment> tag that contains <DirectoryRef> tags.  
Most portions of the WiX installation are represented by one or more of these
objects. 

=head1 METHODS

=head2 Accessors

Accessors take no parameters and return the item requested (listed below)

=cut

use 5.006;
use strict;
use warnings;
use Carp                                 qw{ croak confess       };
use Params::Util                         qw{ _IDENTIFIER _STRING _INSTANCE };
use Data::UUID                           qw{ NameSpace_DNS       };
use File::Spec                           qw{};
use Perl::Dist::WiX::DirectoryTree       qw{};
use Perl::Dist::WiX::Base::Fragment      qw{};
use Perl::Dist::WiX::Files::DirectoryRef qw{};

use vars qw{$VERSION @ISA};
BEGIN {
    $VERSION = '0.11_06';
    @ISA = 'Perl::Dist::WiX::Base::Fragment';
}

=pod

=over 4

=item directory_tree, sitename

Returns the parameter of the same name passed in to L</new>.

=back

    $id = $self->id;

=cut

use Object::Tiny qw{ 
    directory_tree
    sitename
    trace
};

#####################################################################
# Constructors

=head2 new

The B<new> method creates a new files fragment object.

    $fragment = Perl::Dist::WiX::Files->new(
        directory_tree => $self->directories,
        sitename       => $sitename,
        id             => 'Files'
    );

=head2 Parameters

=over 4

=item * 

directory_tree: A <Perl::Dist::WiX::DirectoryTree> object containing 
the base directories of the installation. (See the 
L<Perl::Dist::WiX/Accessors|"directories" accessor> of 
Perl::Dist::Wix for more details.)

=item *

sitename: The site that this installation is being uploaded to. 
Used to create GUIDs.

=back

=cut

sub new {
    my $self = shift->SUPER::new(@_);

    # Apply defaults
    unless (_INSTANCE($self->directory_tree, 'Perl::Dist::WiX::DirectoryTree')) {
        croak('Missing or invalid directory_tree parameter');
    }
    
    unless ( _STRING($self->sitename) ) {
        croak('Missing or invalid sitename parameter - cannot generate GUID without one');
    }
    
    # Debugging switch.
    $self->{trace} = 1;
    
    return $self;
}

sub print {
    my $self = shift;
    if ($self->trace) { print @_; }
    return $self;
}

=head2 add_files(@files)

The B<add_files> method checks that each file in the list is not 
a directory and then calls the add_file method if it is.

    my $self = $self->add_files(@filenames);
    
    my $self = $self->add_files($file1, $file2);

=cut

sub add_files {
    my ($self, @files) = @_;
    
    # Each file could be a directory or have a newline, so fix that and add the files.
    foreach my $file (@files) {
        chomp $file;
        next if not -f $file;

        $self->add_file($file);
    }

    return $self;
}

=head2 add_files($file)

The B<add_file> adds a file to the fragment in the correct place.

    my $self = $self->add_file($file);

=cut

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
    
    $self->print("[Files " . __LINE__ . "] ***** File: $file.\n");

    # Check if we have a DirectoryRef directly contained with the appropriate path.
    my $directory_ref = $self->_search_refs($path, 1);
    if (defined $directory_ref) {
        # Yes, we do. Add the file to this DirectoryRef.
        $self->print("[Files " . __LINE__ . "] Stage 1 - Adding file to DirectoryRef for $path.\n");
        $self->print("[Files " . __LINE__ . "]   Adding file $file.\n");
        $directory_ref->add_file(
            sitename => $self->sitename, 
            filename => $file,
        );
    } else {
# 2. Is there another Directory to create a reference of?
    
        # Check if we have a Directory in the tree to take a reference of.
        $directory_obj = $self->directory_tree->search($path, $self->trace);        
        if (defined $directory_obj) {
            # Yes, we do. Make a DirectoryRef, and attach it.
            $self->print("[Files " . __LINE__ . "] Stage 2 - Creating DirectoryRef for $path.\n");
            $directory_ref = Perl::Dist::WiX::Files::DirectoryRef->new(
                sitename => $self->sitename,
                directory_object => $directory_obj
            );
            $self->add_component($directory_ref);
            
            # Did we get the path that we needed?
            if ($directory_obj->path ne $path) {

                $self->print("[Files " . __LINE__ . "]   Adding path $path.\n");
                $self->print("[Files " . __LINE__ . "]   Adding file $file.\n");
                # Create the directory objects and add the file.
                $directory_obj = $directory_ref->add_directory_path($path);
                $file_obj = $directory_obj->add_file(
                    sitename => $self->sitename, 
                    filename => $file,
                );
                return $file_obj;
            } else {
            
                $self->print("[Files " . __LINE__ . "]   Adding file $file.\n");
                # Add the file.
                $file_obj = $directory_ref->add_file(
                    sitename => $self->sitename, 
                    filename => $file,
                );
                return $file_obj;
            }
        }
    
# 3. Is there a DirectoryRef that's higher up in the directory tree?

        # Get paths for each level up in the tree.
        $directory_obj = undef;
        my @paths = $self->_get_possible_paths($vol, $dirs);
        foreach my $path_portion (@paths) {

            $self->print("[Files " . __LINE__ . "] Stage 3 - Searching $path_portion.\n");
            # Is there a DirectoryRef that exists at this level?
            $directory_ref = $self->_search_refs($path_portion);
            if (defined $directory_ref) {

                $self->print("[Files " . __LINE__ . "] Stage 3 - Found DirectoryRef for $path_portion.\n");
            
                # Do we already have the correct path in Directory objects?.
                $directory_obj = $directory_ref->search($path);
                if (not defined $directory_obj) {

                    $self->print("[Files " . __LINE__ . "]   Adding path $path.\n");
                    # We don't, so add the Directory object(s) required to climb down.
                    $directory_obj = $directory_ref->add_directory_path($path);
                }

                $self->print("[Files " . __LINE__ . "]   Adding file $file.\n");
                # Add the file, now that we have the Directory object we need.
                $file_obj = $directory_obj->add_file(
                    sitename => $self->sitename, 
                    filename => $file,
                );
                return $file_obj;
            }
        }
        
# 4. Search the tree, create a new DirectoryRef and add it to the list.

        # Put the full path back in the list of directories to search for.
        unshift @paths, $path;

        # Search until we find a directory object.
        foreach my $path_portion (@paths) {
        
            # Search the directory tree.
            $directory_obj = $self->directory_tree->search($path_portion);
            if (defined $directory_obj) {

                $self->print("[Files " . __LINE__ . "] Stage 4 - Creating DirectoryRef for $path_portion.\n");
            
                # Make a DirectoryRef and attach it.
                $directory_ref = Perl::Dist::WiX::Files::DirectoryRef->new(
                    sitename => $self->sitename,
                    directory_object => $directory_obj
                );
                $self->add_component($directory_ref);

                # Did we add the file's directory?
                if ($path_portion ne $path) {

                    $self->print("[Files " . __LINE__ . "]   Adding path $path.\n");
                    $self->print("[Files " . __LINE__ . "]   Adding file $file.\n");
                    # Add required directories .
                    $directory_obj = $directory_ref->add_directory_path($path);
                    $file_obj = $directory_obj->add_file(
                        sitename => $self->sitename, 
                        filename => $file,
                        );
                    return $file_obj;
                } else {

                    $self->print("[Files " . __LINE__ . "]   Adding file $file.\n");
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

=head2 as_string

The B<as_string> method converts the component tags within this object  
into strings by calling their own L<Perl::Dist::WiX::Base::Component/"as_string($spaces)"|as_string>
methods and indenting them appropriately.

    my $string = $fragment->as_string;

=cut

sub as_string {
    my $self = shift;
    
    my $string;
    my $s;

    # How many descendants do we have?
    my $count = scalar @{$self->{components}};

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
        $string .= $self->indent(4, $s);
        $string .= "\n";
    }
    
    # End the fragment.
    $string .= <<'EOF';
  </Fragment>
</Wix>
EOF
    return $string;
}

=head2 get_component_array

The B<get_component_array> method returns an array of id attributes 
of components contained within this object.

It does this recursively.

    my @id = $fragment->get_component_array;

=cut

sub get_component_array {
    my $self = shift;

    my $count = scalar @{$self->{components}};
    my @answer;
    
    # Get the array for each descendant.
    foreach my $i (0 .. $count - 1) {
        push @answer, $self->{components}->[$i]->get_component_array;
    }
    
    return @answer;
}

1;
