package Perl::Dist::WiX::DirectoryTree;

use 5.006;
use strict;
use warnings;
use Carp                        qw{ croak confess verbose      };
use Params::Util                qw{ _IDENTIFIER _STRING };
use Perl::Dist::WiX::Directory  qw{};
use Perl::Dist::WiX::Misc       qw{};

use vars qw{$VERSION @ISA};
BEGIN {
    $VERSION = '0.11_06';
    @ISA = 'Perl::Dist::WiX::Misc'
}

use Object::Tiny qw{
    root
    sitename
    app_dir
    app_name
};

sub new {
    my $self = shift->SUPER::new(@_);

    print "Creating in-memory directory tree...\n";

    $self->{root} = Perl::Dist::WiX::Directory->new(id => 'TARGETDIR', name => 'SourceDir', special => 1);
    $self->initialize_tree($self->app_dir, $self->app_name);
    
    return $self;
}

sub search {
    my ($self, $path) = @_;
    
    return $self->root->{directories}->[0]->search($path);
}

sub initialize_tree {
    my $self = shift;

    my $branch = $self->root->add_directory({
        id => 'App_Root', 
        name => '[INSTALLDIR]', 
        path => $self->app_dir
    });
    
    $self->root
         ->add_directory({id => 'ProgramMenuFolder', special => 2})
         ->add_directory({id => 'App_Menu',        special => 1, name=> $self->app_name});
         
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
        perl\site
        perl\site\lib
    ));
}

sub as_string {
    my $self = shift;
    return $self->indent(4, $self->root->as_string);
}

1;