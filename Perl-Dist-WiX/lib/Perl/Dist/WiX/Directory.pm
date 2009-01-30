package Perl::Dist::WiX::Directory;

#####################################################################
# Perl::Dist::WiX::Files::Directory - Class for a <Directory> tag.
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
use Carp                              qw( croak verbose           );
use Params::Util                      
        qw( _IDENTIFIER _STRING _NONNEGINT _INSTANCE _HASH );
use Data::UUID                        qw( NameSpace_DNS    );
use File::Spec::Functions             qw( catdir splitdir );
require Perl::Dist::WiX::Base::Component;
require Perl::Dist::WiX::Base::Entry;
require Perl::Dist::WiX::Files::Component;
require Perl::Dist::WiX::Misc;

use vars qw( $VERSION @ISA );
BEGIN {
    $VERSION = '0.11_07';
    @ISA = qw(Perl::Dist::WiX::Base::Component
              Perl::Dist::WiX::Base::Entry
              Perl::Dist::WiX::Misc
             );
}

#####################################################################
# Accessors:
#   name, path, special: See constructor.
#   files: Returns an arrayref of the Files::Component objects 
#     contained in this object.
#   directories: Returns an arrayref of the other Direcotry objects 
#     contained in this object.

use Object::Tiny qw{
    name
    path
    special
    files
    directories
};

#####################################################################
# Constructor for Directory
#
# Parameters: [pairs]
#   name: The name of the directory to create.
#   path: The path to and including the directory on the local filesystem.
#   special: [integer] defaults to 0, 1 = Id should not be prefixed, 
#     2 = directory without name

sub new {
    my $self = shift->Perl::Dist::WiX::Base::Component::new(@_);

    # Check parameters.
    if (not defined _NONNEGINT($self->special)) {
        $self->{special} = 0;
    }
    if (($self->special == 0) && (not _STRING($self->path))) {
        croak 'Missing or invalid path';
    }
    if ((not defined _STRING($self->guid)) && (not defined _STRING($self->id))) {
        $self->create_guid_from_path;
        $self->{id} = $self->{guid};
        $self->{id} =~ s{-}{_}g;
    }

    # Initialize arrayrefs.
    $self->{directories} = [];
    $self->{files}       = [];
    
    return $self;
}

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
    my $self = shift;
    my $params_ref = { @_ };
    my $path = $self->path;

    # Set defaults for parameters.
    my $path_to_find = _STRING($params_ref->{path_to_find}) || croak("No path to find.");
    my $descend      = $params_ref->{descend} || 1;
    my $exact        = $params_ref->{exact}   || 0;
    
    $self->trace_line( 3, "Looking for $path_to_find\n");
    $self->trace_line( 4, "  in:      $path.\n");
    $self->trace_line( 5, "  descend: $descend exact: $exact.\n");
    
    # If we're at the correct path, exit with success!
    if ((defined $path) && ($path_to_find eq $path)) {
        $self->trace_line( 4, "Found $path.\n");
        return $self;
    }
    
    # Quick exit if required.
    if (not $descend) {
        return undef;
    }
    
    # Do we want to continue searching down this direction?
    my $subset = "$path_to_find\\" =~ m/\A\Q$path\E\\/;
    if (not $subset) {
        $self->trace_line(4, "Not a subset in: $path.\n");
        $self->trace_line(5, "  To find: $path_to_find.\n");
        return undef;
    }
    
    # Check each of our branches.
    my $count = scalar @{$self->{directories}};
    my $answer;
    $self->trace_line(4, "Number of directories to search: $count\n");
    foreach my $i (0 .. $count - 1) {
        $self->trace_line(5, "Searching directory #$i in $path\n");
        $answer = $self->{directories}->[$i]->search_dir(%{$params_ref});
        if (defined $answer) {
            return $answer;
        }
    }
    
    # If we get here, we did not find a lower directory.
    return $exact ? undef : $self; 
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
    my $path = $self->path;
    
    # Check required parameters.
    unless (_STRING($filename)) {
        croak 'Missing or invalid filename parameter';
    }

    # Do we want to continue searching down this direction?
    my $subset = $filename =~ m/\A\Q$path\E/;
    return undef if not $subset;

    # Check each of our branches.
    my $count = scalar @{$self->{files}};
    my $answer;
    foreach my $i (0 .. $count - 1) {
        next if (not defined $self->{files}->[$i]);
        $answer = $self->{files}->[$i]->is_file($filename);
        if ($answer) {
            return [$self, $i];
        }
    }
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

sub delete_filenum { $_[0]->{files}->[$_[1]] = undef; return $_[0]; }

########################################
# add_directories_id(($id, $name)...)
# Parameters: [repeatable in pairs]
#   $id:   ID of directory object to create.
#   $name: Name of directory to create object for.
# Returns:
#   Object being operated on. (chainable)

sub add_directories_id {
    my ($self, @params) = @_;
    
    # We need id, name pairs passed in. 
    if ($#params % 2 != 1) {     # The test is weird, but $#params is one less than the actual count.
        croak ('Odd number of parameters to add_directories_id');
    }
    
    # Add each individual id and name.
    my ($id, $name);
    while ($#params > 0) {
        $id   = shift @params;
        $name = shift @params;
        if ($name =~ m{\\}) {
            $self->add_directory({
                id => $id, 
                path => $name, 
            });
        } else {
            $self->add_directory({
                id => $id, 
                path => $self->path . '\\' . $name, 
                name => $name,
            });
        }
    }
    
    return $self;
}

########################################
# add_directories_init(@dirs)
# Parameters: 
#   @dirs: List of directories to create object for.
# Returns:
#   Object being operated on. (chainable)

sub add_directories_init {
    my ($self, @params) = @_;
    
    my $name;
    while ($#params >= 0) {
        $name = shift @params;
        next if not defined $name;
        if (substr($name, -1) eq '\\') {
            $name = substr($name, 0, -1);
        }
        $self->add_directory({
            path => $self->path . '\\' . $name,
        });
    }
    
    return $self;
}

########################################
# add_directory_path($path)
# Parameters: 
#   @path: Path of directories to create object(s) for.
# Returns:
#   Directory object created.

sub add_directory_path {
    my ($self, $path) = @_;

    # Check required parameters.
    unless (_STRING($path)) {
        croak 'Missing or invalid path parameter';
    }

    if (substr($path, -1) eq '\\') {
        $path = substr($path, 0, -1);
    }
    
    if (! $self->path =~ m{\A\Q$path\E}) {
        croak q{Can't add the directories required};
    }

    # Get list of directories to add.   
    my $path_to_remove = $self->path;
    $path =~ s{\A\Q$path_to_remove\E\\}{};
    my @dirs = File::Spec->splitdir($path);
    
    # Get rid of empty entries at the beginning.
    while ($dirs[-1] eq q{}) {
        pop @dirs;
    }
    
    my $directory_obj = $self;
    my $path_create = $self->path;
    my $name_create;
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
# add_directory($params_ref)
# Parameters: [hashref in $params_ref]
#   see new.
# Returns:
#   Directory object created.

sub add_directory {
    my ($self, $params_ref) = @_;

    # Check parameters.
    unless (_HASH($params_ref)) {
        croak('Parameters not passed in hash reference'); 
    }
    
    # Check required parameters.
    if (((not defined $params_ref->{special}) or 
         ($params_ref->{special} == 0)) and 
        (not _STRING($params_ref->{path})))  {
        croak 'Missing or invalid path parameter';
    }

    # This way we don't need to pass in the sitename or the trace.
    $params_ref->{sitename} = $self->sitename;
    $params_ref->{trace} = $self->{trace};
    
    # If we have a name or a special code, we create it under here.
    if ((defined $params_ref->{name}) || (defined $params_ref->{special})) {
        defined $params_ref->{name} ?
            $self->trace_line(4, "Adding directory $params_ref->{name}\n") :
            $self->trace_line(4, "Adding directory Id $params_ref->{id}\n");
        my $i = scalar @{$self->{directories}};
        $self->{directories}->[$i] = Perl::Dist::WiX::Directory->new(%{$params_ref});
        return $self->{directories}->[$i];
    } else {
        $self->trace_line(4, "Adding $params_ref->{path}\n");
        my $path = $params_ref->{path};
        
        # Find the directory object where we want to create this directory.
        my ($volume, $directories, undef) = File::Spec->splitpath( $path, 1 );
        my @dirs = splitdir($directories);
        my $name = pop @dirs; # to eliminate the last directory.
        $directories = catdir(@dirs);
        my $directory = $self->search_dir(
            path_to_find => catdir($volume, $directories),
            descend => 1,
            exact   => 1,
        );
        if (not defined $directory) {
            croak "Can't create intermediate directories when creating $path (unsuccessful search for $volume$directories)";
        }
        
        # Add the directory there.
        $params_ref->{name} = $name;
        $directory->add_directory($params_ref);
        return $directory;
    }
}

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
    my ($self, $directory_obj) = @_;

    # Check for a valid Directory or DirectoryRef object.
    unless (_INSTANCE($directory_obj, 'Perl::Dist::WiX::Directory') or
            _INSTANCE($directory_obj, 'Perl::Dist::WiX::Files::DirectoryRef')
    ) {
        croak('Invalid directory object passed in.');
    }

    my $path_to_check = $directory_obj->path;
    my $path = $self->path;
    if (not defined $path_to_check) {
        $self->trace_line(5, "Is Child Of: Answer: No path detected (0)\n");
        return 0;
    }
    my $answer = "$path\\" =~ m{\A\Q$path_to_check\E\\} ? 1 : 0;
    $self->trace_line(5, "Is Child Of: Answer: $answer\n  Path: $path\n  Path to check: $path_to_check\n");
    return $answer;
}

########################################
# add_file(...)
# Parameters: [pairs]
#   See Files::Component->new. 
# Returns:
#   Files::Component object created.

sub add_file {
    my ($self, @params) = @_;

    my $i = scalar @{$self->{files}};
    $self->{files}->[$i] = Perl::Dist::WiX::Files::Component->new(@params);
    return $self->{files}->[$i];
}

########################################
# create_guid_from_path
# Parameters: 
#   None. 
# Returns:
#   Object being operated on. (chainable)
# Action:
#   Creates a GUID and sets $self->{guid} to it.

sub create_guid_from_path {
    my $self = shift;

    # Check parameters.
    unless ( _STRING($self->sitename) ) {
        croak("Missing or invalid sitename param - cannot generate GUID without one");
    }
    unless ( _STRING($self->path) ) {
        croak("Missing or invalid id param - cannot generate GUID without one");
    }
    my $guidgen = Data::UUID->new();
    # Make our own namespace...
    my $uuid = $guidgen->create_from_name(Data::UUID::NameSpace_DNS, $self->sitename);
    #... then use it to create a GUID out of the path.
    $self->{guid} = uc $guidgen->create_from_name_str($uuid, $self->path);
    
    return $self;
}

########################################
# get_component_array
# Parameters:
#   None
# Returns:
#   Array of Ids attached to the contained directory and file objects.

sub get_component_array {
    my $self = shift;
    
    my $count = scalar @{$self->{directories}};
    my @answer;
    my $id;

    # Get the array for each descendant.
    foreach my $i (0 .. $count - 1) {
        push @answer, $self->{directories}->[$i]->get_component_array;
    }

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
#   $tree: 1 if printing directory tree. [i.e. DO print empty directories.]
# Returns:
#   String representation of the <Directory> tag represented
#   by this object, and the <Directory> and <File> tags
#   contained in it.

sub as_string {
    my ($self, $tree) = @_;
    my ($count, $answer); 
    my $string = q{};
    if (not defined $tree) { $tree = 0; }
    
    # Get string for each subdirectory.
    $count = scalar @{$self->{directories}};
    foreach my $i (0 .. $count - 1) {
        $string .= $self->{directories}->[$i]->as_string($tree);
    }
    
    # Get string for each file this directory contains.
    $count = scalar @{$self->{files}};
    foreach my $i (0 .. $count - 1) {
        next if (not defined $self->{files}->[$i]);
        $string .= $self->{files}->[$i]->as_string;
    }

    # Short circuits...
    if (($string eq q{}) and ($self->special == 0) and ($tree == 0)) { return q{}; }
    if (($string eq q{}) and ($self->id eq 'TARGETDIR')) { return q{}; }
    
    # Now make our own string, and put what we've already got within it. 
    if ((defined $string) && ($string ne q{})) {
        if ($self->special == 2) {
            $answer = "<Directory Id='D_$self->{id}'>\n";
            $answer .= $self->indent(2, $string);
            $answer .= "\n</Directory>\n";
        } elsif ($self->id eq 'TARGETDIR') {
            $answer = "<Directory Id='$self->{id}' Name='$self->{name}'>\n";
            $answer .= $self->indent(2, $string);
            $answer .= "\n</Directory>\n";
        } else {
            $answer = "<Directory Id='D_$self->{id}' Name='$self->{name}'>\n";
            $answer .= $self->indent(2, $string);
            $answer .= "\n</Directory>\n";
        }
    } else {
        if ($self->special == 2) {
            $answer = "<Directory Id='D_$self->{id}' />\n";
        } else {
            $answer = "<Directory Id='D_$self->{id}' Name='$self->{name}' />\n";
        }
    }

    return $answer;
}

1;
