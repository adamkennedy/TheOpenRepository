package Perl::Dist::WiX::DirectoryTree;

#####################################################################
# Perl::Dist::WiX::DirectoryTree - Class containing initial tree of 
#   <Directory> tag objects.
#
# Copyright 2009 Curtis Jewell
#
# License is the same as perl. See Wix.pm for details.

use 5.006;
use strict;
use warnings;
use Carp             qw( croak               );
use Params::Util     qw( _IDENTIFIER _STRING );
require Perl::Dist::WiX::Directory;
require Perl::Dist::WiX::Misc;

use vars qw($VERSION @ISA);
BEGIN {
    $VERSION = '0.11_06';
    @ISA = 'Perl::Dist::WiX::Misc'
}

#####################################################################
# Accessors:
#   root: Returns the root of the directory tree created by new.
#   sitename: Returns the sitename passed in to new.

use Object::Tiny qw(
    root
    sitename
);

#####################################################################
# Constructor for DirectoryTree
#
# Parameters: [pairs]
#   app_name: The name of the distribution being created.
#   app_dir: The location on disk of the distribution being created.
#   sitename: The name of the site that is hosting the download.

sub new {
    my $self = shift->SUPER::new(@_);

    print "Creating in-memory directory tree...\n";

    $self->{root} = Perl::Dist::WiX::Directory->new(id => 'TARGETDIR', name => 'SourceDir', special => 1);
    $self->initialize_tree($self->{app_dir}, $self->{app_name});
    
    return $self;
}

########################################
# search($path)
# Parameters:
#   $path: Path to find.
# Returns:
#   Directory object representing $path or undef.

sub search {
    my ($self, $path, $trace) = @_;
    
    return $self->root->{directories}->[0]->search($path, $trace);
}

########################################
# initialize_tree
# Parameters:
#   None.
# Returns:
#   Object being operated on (chainable).
# Action:
#   Creates Directory objects representing the base 
#   of a Perl distribution's directory tree.
# Note:
#   Any directory that's used in more than one fragment needs to 
#   be created in this routine, otherwise light.exe will bail with
#   a duplicate symbol [LGHT0091] error.

sub initialize_tree {
    my $self = shift;

    # Create starting directories.
    my $branch = $self->root->add_directory({
        id => 'App_Root', 
        name => '[INSTALLDIR]', 
        path => $self->{app_dir}
    });
    $self->root
         ->add_directory({id => 'ProgramMenuFolder', special => 2})
         ->add_directory({id => 'App_Menu',          special => 1, name=> $self->{app_name}});  
    $branch->add_directories_id(
        'Perl',      'perl',
        'Toolchain', 'c',
        'License',   'licenses',
        'Cpan',      'cpan',
        'Win32',     'win32'
        );
    $branch->add_directories_init($self->sitename, qw(
        c\bin
        c\bin\startup
        c\include
        c\include\c++
        c\include\c++\3.4.5
        c\include\c++\3.4.5\backward
        c\include\c++\3.4.5\bits
        c\include\c++\3.4.5\debug
        c\include\c++\3.4.5\ext
        c\include\c++\3.4.5\mingw32
        c\include\c++\3.4.5\mingw32\bits
        c\include\ddk
        c\include\gl
        c\include\libxml
        c\include\sys
        c\lib
        c\lib\debug
        c\lib\gcc
        c\lib\gcc\mingw32
        c\lib\gcc\mingw32\3.4.5
        c\lib\gcc\mingw32\3.4.5\include
        c\lib\gcc\mingw32\3.4.5\install-tools
        c\lib\gcc\mingw32\3.4.5\install-tools\include
        c\libexec
        c\libexec\gcc
        c\libexec\gcc\mingw32
        c\libexec\gcc\mingw32\3.4.5
        c\libexec\gcc\mingw32\3.4.5\install-tools
        c\mingw32
        c\mingw32\bin
        c\mingw32\lib
        c\mingw32\lib\ld-scripts
        c\share
        c\share\locale
        licenses\dmake
        licenses\gcc
        licenses\mingw
        licenses\perl
        licenses\pexports
        perl\bin
        perl\lib
        perl\lib\auto
        perl\lib\auto\share
        perl\site
        perl\site\lib
        perl\site\lib\auto
        perl\site\lib\auto\share        
        perl\site\lib\Win32
    ));
    
    return $self;
}

########################################
# as_string
# Parameters:
#   None
# Returns:
#   String representation of the <Directory> tags this object contains.

sub as_string {
    my $self = shift;
    return $self->indent(4, $self->root->as_string);
}

1;