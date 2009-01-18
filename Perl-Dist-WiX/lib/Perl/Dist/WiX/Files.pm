package Perl::Dist::WiX::Files;

use 5.006;
use strict;
use warnings;
use Carp                                 qw{ croak confess       };
use Params::Util                         qw{ _IDENTIFIER _STRING _INSTANCE };
use Data::UUID                           qw{ NameSpace_DNS       };
use File::Spec                           qw{};
use Perl::Dist::WiX::DirectoryTree       qw{};
use Perl::Dist::WiX::Base::Fragment      qw{};
use Perl::Dist::WiX::Base::Component     qw{};
use Perl::Dist::WiX::Files::DirectoryRef qw{};
use Object::Tiny                         qw{ directory_tree };

use vars qw{$VERSION @ISA};
BEGIN {
    $VERSION = '0.11_04';
    @ISA = 'Perl::Dist::WiX::Base::Fragment';
}

#####################################################################
# Constructors

sub new {
    my $self = shift->SUPER::new(@_);

    # Apply defaults
    unless ( _STRING( $self->id )) {
        croak('Missing or invalid id parameter');
    }

    unless (_INSTANCE($self->directory_tree, 'Perl::Dist::WiX::DirectoryTree')) {
        croak('Missing or invalid directory_tree parameter');
    }
    
    unless ( _STRING($self->sitename) ) {
        croak('Missing or invalid sitename parameter - cannot generate GUID without one');
    }
    
    return $self;
}

sub add_files {
    my ($self, @files) = @_;
    my $component;
    
    foreach my $file (@files) {
        chomp $file;
        next if not -f $file;

        $self->add_file($file);
    }

    return $self;
}

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
    
    # Is there a DirectoryRef for this path?
    my $directory_ref = $self->search_refs($path);
    if (defined $directory_ref) {
        # Yes, add the file to this DirectoryRef.
        $directory_ref->add_file(sitename => $self->sitename, filename => $file);
    } else {
        # Check for a DirectoryRef that's higher up in the directory tree.
        
        # If there is one, add directory(ies) there, and the file to it.
        # If not, search the tree, create a new DirectoryRef and add it to the list.

        # Get paths for each level up in the tree.
        $directory_obj = undef;
        my @paths = $self->_get_possible_paths($vol, $dirs);
        foreach my $path_portion (@paths) {

            # Is there a DirectoryRef at this level?
            $directory_ref = $self->search_refs($path_portion);
            if (defined $directory_ref) {
            
                $directory_obj = $directory_ref->search($path);
                if (not defined $directory_obj) {

                    # Yes, add the directories required to climb down and then the file.
                    $directory_obj = $directory_ref->add_directory_path($path);
                }

                $file_obj = $directory_obj->add_file(
                    sitename => $self->sitename, 
                    filename => $file
                );
                return $file_obj;
            }
        }
        
        # No, we did not find a higher DirectoryRef, so we create one.
        if (not defined $directory_ref) {

        # Put the full path back in the list of directories to search for.
            unshift @paths, $path;

            # Search until we find a directory object.
            foreach my $path_portion (@paths) {
            
                # Search the directory tree.
                $directory_obj = $self->directory_tree->search($path_portion);
                if (defined $directory_obj) {

                    # Create a reference.
                    $directory_ref = Perl::Dist::WiX::Files::DirectoryRef->new(
                        sitename => $self->sitename,
                        directory_object => $directory_obj
                    );

                    # Add it to the list.
                    $self->add_component($directory_ref);

                    # Did we add the file's directory?
                    if ($path_portion ne $path) {

                        # Add required directories and the file.
                        $directory_obj = $directory_ref->add_directory_path($path);

                        $file_obj = $directory_obj->add_file(
                            sitename => $self->sitename, 
                            filename => $file
                            );
                        return $file_obj;
                    } else {

                        # Add the file.
                        $file = $directory_ref->add_file(
                            sitename => $self->sitename, 
                            filename => $file
                        );
                        return $file_obj;
                    }
                }
            }
        }
    }
    
    # Completely unsuccessful.
    return undef;
}

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

sub search_refs {
    my ($self, $path_to_find) = @_;

    my $answer = undef;
 
    # How many descendants do we have?
    my $count = scalar @{$self->{components}};

    # Pass the search down to each our descendants.
    foreach my $i (0 .. $count - 1) {
        $answer = $self->{components}->[$i]->search($path_to_find);

        # Exit if one of our descendants is successful.
        return $answer if defined $answer;
    }

    # We were unsuccessful.
    return undef;
}

sub as_string {
    my ($self) = shift;
    
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

1;
