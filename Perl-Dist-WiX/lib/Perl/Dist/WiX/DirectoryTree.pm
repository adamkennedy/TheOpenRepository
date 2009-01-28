package Perl::Dist::WiX::DirectoryTree;

#####################################################################
# Perl::Dist::WiX::DirectoryTree - Class containing initial tree of 
#   <Directory> tag objects.
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
use Carp             qw( croak               );
use Params::Util     qw( _IDENTIFIER _STRING );
require Perl::Dist::WiX::Directory;
require Perl::Dist::WiX::Misc;

use vars qw($VERSION @ISA);
BEGIN {
    $VERSION = '0.11_07';
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

    $self->trace_line( 2, "Creating in-memory directory tree...\n");

    $self->{root} = Perl::Dist::WiX::Directory->new(
        id => 'TARGETDIR', 
        name => 'SourceDir', 
        special => 1,
        sitename => $self->sitename,
        trace => $self->{trace});
    
    return $self;
}

########################################
# search_dir($path)
# Parameters: [pairs]
#   path_to_find: Path being searched for.
#   descend: 1 if can descend to lower levels, [default]
#            0 if has to be on this level.
#   exact:   1 if has to be equal, 
#            0 if equal or subset. [default] 
# Returns:
#   Directory object representing $path or undef.

sub search_dir {
    my $self = shift;
    my $params_ref = { @_ };

    # Set defaults for parameters.
    my $path_to_find = $params_ref->{path_to_find} || croak("No path to find.");
    my $descend = $params_ref->{descend} || 1;
    my $exact   = $params_ref->{exact}   || 0;
        
    return $self->root->{directories}->[0]->search_dir(
        path_to_find => $path_to_find, 
        descend => $descend,
        exact => $exact,
    );
}

########################################
# initialize_tree(@dirs)
# Parameters:
#   @dirs: Additional directories to create.
# Returns:
#   Object being operated on (chainable).
# Action:
#   Creates Directory objects representing the base 
#   of a Perl distribution's directory tree.
# Note:
#   Any directory that's used in more than one fragment needs to 
#   be either in this routine or passed to it, otherwise light.exe WILL 
#   bail with a duplicate symbol [LGHT0091] or duplicate primary key 
#   [LGHT0130] error and will NOT create an MSI.
# Note #2:
#   Directories passed to this routine should not include the 
#   installation directory. (e.g, perl\share rather than 
#   C:\strawberry\perl\share.)

sub initialize_tree {
    my ($self, @dirs) = @_;

    $self->trace_line( 2, "Initializing directory tree.\n");
    
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
    $branch->add_directories_init(qw(
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
        perl\lib\Compress
        perl\lib\CPAN
        perl\lib\CPAN\API
        perl\lib\Digest
        perl\lib\Digest\MD5
        perl\lib\ExtUtils
        perl\lib\ExtUtils\CBuilder
        perl\lib\ExtUtils\CBuilder\Platform
        perl\lib\File
        perl\lib\IO
        perl\lib\IO\Compress
        perl\lib\IO\Compress\Adapter
        perl\lib\IO\Compress\Base
        perl\lib\IO\Compress\Gzip
        perl\lib\IO\Compress\Zip
        perl\lib\IO\Uncompress
        perl\lib\IO\Uncompress\Adapter
        perl\lib\Math
        perl\lib\Math\BigInt
        perl\lib\Math\BigInt\FastCalc
        perl\lib\Module
        perl\lib\Test
        perl\lib\auto
        perl\lib\auto\Compress
        perl\lib\auto\Cwd
        perl\lib\auto\Digest
        perl\lib\auto\Digest\MD5
        perl\lib\auto\Math
        perl\lib\auto\Math\BigInt
        perl\lib\auto\Math\BigInt\FastCalc
        perl\lib\auto\share
        perl\site
        perl\site\lib
        perl\site\lib\Bundle
        perl\site\lib\Compress
        perl\site\lib\DBD
        perl\site\lib\File
        perl\site\lib\HTML
        perl\site\lib\IO
        perl\site\lib\LWP
        perl\site\lib\Math
        perl\site\lib\PAR
        perl\site\lib\Term
        perl\site\lib\Test
        perl\site\lib\Win32
        perl\site\lib\XML
        perl\site\lib\auto
        perl\site\lib\auto\share
        perl\site\lib\auto\Compress
        perl\site\lib\auto\Compress\Raw
        perl\site\lib\auto\Math
        perl\site\lib\auto\Term
        perl\site\lib\auto\Win32
        perl\site\lib\auto\XML
    ), @dirs);
    
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
    return $self->indent(4, $self->root->as_string(1));
}

1;