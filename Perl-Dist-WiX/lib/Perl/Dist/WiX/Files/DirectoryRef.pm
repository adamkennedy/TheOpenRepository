package Perl::Dist::WiX::Files::DirectoryRef;

#####################################################################
# Perl::Dist::WiX::Files::DirectoryRef - Class for a <DirectoryRef> tag.
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
use Carp            qw( croak                                    );
use Params::Util    qw( _IDENTIFIER _STRING _INSTANCE _NONNEGINT );
require Perl::Dist::WiX::Base::Component;
require Perl::Dist::WiX::Base::Entry;
require Perl::Dist::WiX::Misc;

use vars qw( $VERSION @ISA );
BEGIN {
    $VERSION = '0.11_07';
    @ISA = qw (Perl::Dist::WiX::Base::Component
               Perl::Dist::WiX::Base::Entry
               Perl::Dist::WiX::Misc
              );
}

#####################################################################
# Accessors:
#   directory_object: Returns the filename parameter passed in by new.

use Object::Tiny qw{
    directory_object
};

#####################################################################
# Constructor for Files::DirectoryRef
#
# Parameters: [pairs]
#   directory_object: The ::WiX::Directory object being referred to.
#   sitename: The name of the site that is hosting the download.

sub new {
    my $self = shift->Perl::Dist::WiX::Base::Component::new(@_);
    
    if (not _INSTANCE($self->directory_object, 'Perl::Dist::WiX::Directory')) {
        croak 'Missing or invalid directory object';
    }

    if (not _STRING($self->sitename)) {
        croak 'Missing or invalid sitename';
    }
    
    $self->{directories} = [];
    $self->{files}       = [];
    
    return $self;
}


#####################################################################
# Main Methods

########################################
# path
# Parameters: 
#   None.
# Returns:
#   Path of the directory object being referenced.

sub path { return $_[0]->directory_object->path; }

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
    my $self = shift;
    my $params_ref = { @_ };

    # Set defaults for parameters.
    my $path_to_find = _STRING($params_ref->{path_to_find}) || croak("No path to find.");
    my $descend      = $params_ref->{descend} || 1;
    my $exact        = $params_ref->{exact}   || 0;
    
    # Get OUR path.
    my $path = $self->directory_object->path;
    
    $self->trace_line( 3, "Looking for $path_to_find\n");
    $self->trace_line( 4, "  in: $path.\n");
    $self->trace_line( 5, "  descend: $descend.\n");
    $self->trace_line( 5, "  exact:   $exact.\n");

    # Success!
    if ((defined $path) && ($path_to_find eq $path)) {
        $self->trace_line( 4, "Found $path.\n");
        return $self;
    }

    # Quick exit if required.
    if (not $descend) {
        return undef;
    }
    
    # Do we want to continue searching down this direction?
    my $subset = $path_to_find =~ m/\A\Q$path\E/;
    if (not $subset) {
        $self->trace_line( 4, "Not a subset\n");
        $self->trace_line( 4, "  in: $path.\n");
        $self->trace_line( 5, "  To find: $path_to_find.\n");
        return undef;
    }
    
    # Check each of our branches.
    my $count = scalar @{$self->{directories}};
    my $answer = undef;
    foreach my $i (0 .. $count - 1) {
        $answer = $self->{directories}->[$i]->search_dir(%{$params_ref});
        if (defined $answer) {
            return $answer;
        }
    }
    
    # If we get here, we did not find a directory, and we're the last subset if applicable.
    if (not $exact) {
        $self->trace_line( 5, "Found $path as subset.\n");
        return $self;
    } else {
        return undef;
    }    
}

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
    my ($self, $filename) = @_;

    # Check parameters
    if (not _STRING($filename)) {
        croak 'Missing or invalid filename parameter';
    }
    
    # Get OUR path.
    my $path = $self->directory_object->path;
    
    # Do we want to continue searching down this direction?
    my $subset = ("$filename\\" =~ m/\A\Q$path\E\\/) ? 1 : 0;
    return undef if not $subset;

    # Check each file we contain.
    my $count = scalar @{$self->{files}};
    my $answer;
    foreach my $i (0 .. $count - 1) {
        next if (not defined $self->{files}->[$i]);
        $answer = $self->{files}->[$i]->is_file($filename);
        if ($answer == 1) {
            return [$self, $i];
        }
    }

    # Check each of our branches.
    $count = scalar @{$self->{directories}};
    $answer = undef;
    foreach my $i (0 .. $count - 1) {
        $answer = $self->{directories}->[$i]->search_file($filename);
        if (defined $answer) {
            return $answer;
        }
    }

    return undef;
}

########################################
# delete_filenum($i)
# Parameters:
#   $i: Index of file to delete
# Returns:
#   Object being operated on. (chainable)

sub delete_filenum {
    my ($self, $i) = @_;
    
    # Check parameters
    if (not defined _NONNEGINT($i)) {
        croak 'Missing or invalid index parameter';
    }

    # Delete the file. (The object should disappear once its reference is set to undef)
    $self->{files}->[$i] = undef;
    
    return $self;
}

########################################
# add_directory({path => ?, name => ?})
# Parameters: [pairs within hashref]
#   path: Path of directory to create.
#   name: Name of directory to create.
# Returns:
#   True if this is the object for this filename.

sub add_directory {
    my ($self, $params_ref) = @_;

    # Check parameters
    if (not _STRING($params_ref->{path})) {
        croak 'Missing or invalid path parameter';
    }
    
    # If we have a name, we create the directory object under here.
    if (defined $params_ref->{name})
    {
        # Create our WiX::Directory object and attach and return it.
        my $i = scalar @{$self->{directories}};
        $self->{directories}->[$i] = Perl::Dist::WiX::Directory->new(
            sitename => $self->sitename, 
            path => $params_ref->{path}, 
            name => $params_ref->{name},
            trace => $self->{trace},
        );
        return $self->{directories}->[$i];
    } else {
        # Catchable error condition.
        croak q{Can't create intermediate directories.};
    }
}

########################################
# is_child_of($directory_object)
# Parameters:
#   $directory_object: Directory object to compare to.
# Returns: [boolean]
#   True if we are a child of the directory object passed in.

sub is_child_of {
    my ($self, $directory_obj) = @_;

    # Check for a valid Directory or DirectoryRef object.
    unless (_INSTANCE($directory_obj, 'Perl::Dist::WiX::Directory') or
            _INSTANCE($directory_obj, 'Perl::Dist::WiX::Files::DirectoryRef')
    ) {
        croak('Invalid directory object passed in.');
    }
    
    my $path_to_check = $directory_obj->path;

    # Returns false if the object is a "special".
    if (not defined $path_to_check) {
        return 0;
    }
    
    my $path = $self->directory_object->path;
    
    # Do the check.
    return ( "$path\\" =~ m{\A\Q$path\E\\})
}

########################################
# add_file(...)
# Parameters:
#   See WiX::Files::Component->new.
# Returns:
#   The WiX::Files::Component object added.

sub add_file {
    my ($self, @params) = @_;

    # Check parameters
    if (-1 == scalar @params) {
        croak 'Missing file parameter';
    }
    foreach my $j (0 .. scalar @params - 1) {
        if (not _STRING($params[$j])) {
            croak 'Missing or invalid file[$j] parameter';
        }
    }

    # Where are we going to add the file?
    my $i = scalar @{$self->{files}};
    
    # Create the file component and return it.
    $self->{files}->[$i] = Perl::Dist::WiX::Files::Component->new(@params);
    return $self->{files}->[$i];
}

########################################
# add_directory_path($path)
# Parameters:
#   $path: The directory path to add.
# Returns:
#   The last WiX::Directory object added.

sub add_directory_path {
    my ($self, $path) = @_;

    # Check parameters
    if (not _STRING($path)) {
        croak 'Missing or invalid path parameter';
    }

    # Make sure we don't have a trailing slash.
    if (substr($path, -1) eq '\\') {
        $path = substr($path, 0, -1);
    }

    # Croak if we can't create this path under us.
    if (! $self->directory_object->path =~ m{\A\Q$path\E}) {
        croak q{Can't add the directories required};
    }

    # Get list of directories to add.   
    my $path_to_remove = $self->directory_object->path;
    $path =~ s{\A\Q$path_to_remove\E\\}{};
    my @dirs = File::Spec->splitdir($path);
    
    # Get rid of empty entries at the beginning.
    while ($dirs[-1] eq q{}) {
        pop @dirs;
    }

    # Set up the loop.
    my $directory_obj = $self;
    my $path_create = $self->directory_object->path;
    my $name_create;

    # Loop and create directory objects required.
    while ($#dirs != -1) {
        $name_create = shift @dirs;
        $path_create = File::Spec->catdir($path_create, $name_create);
        
        $directory_obj = $directory_obj->add_directory({
            sitename => $self->sitename, 
            name => $name_create,
            path => $path_create,
            trace => $self->{trace},
        });
    }
    
    return $directory_obj;
}

########################################
# get_component_array
# Parameters:
#   None
# Returns:
#   The Id attributes of all the components contained within this object.

sub get_component_array {
    my $self = shift;
    my @answer;

    # Get the array for each descendant.
    my $count = scalar @{$self->{directories}};
    foreach my $i (0 .. $count - 1) {
        push @answer, $self->{directories}->[$i]->get_component_array;
    }

    # Get the Id entries for Files::Component entries we own.
    $count = scalar @{$self->{files}};
    foreach my $i (0 .. $count - 1) {
        next if (not defined $self->{files}->[$i]);
        push @answer, $self->{files}->[$i]->id;
    }

    return @answer;
}

########################################
# as_string
# Parameters:
#   None
# Returns:
#   String representation of <DirectoryRef> tag represented by this object,
#   along with the <Component> and <Directory> entries it contains.

sub as_string {
    my $self = shift;
    my ($count, $answer, $string); 

    # Get our own Id and print it.
    my $id = $self->directory_object->id;
    $answer = "<DirectoryRef Id='D_$id'>\n";
    
    # Stringify the WiX::Directory objects we own.
    $count = scalar @{$self->{directories}};
    foreach my $i (0 .. $count - 1) {
        $string .= $self->{directories}->[$i]->as_string;
    }
    
    # Stringify the WiX::Files::Component objects we own.
    $count = scalar @{$self->{files}};
    foreach my $i (0 .. $count - 1) {
        next if (not defined $self->{files}->[$i]);
        $string .= $self->{files}->[$i]->as_string;
    }
    
    if ((not defined $string) or ($string eq q{})) { 
        return q{}; 
    }
    
    # Finish up.
    $answer .= $self->indent(2, $string);
    $answer .= "\n</DirectoryRef>\n";

    return $answer;
}

1;