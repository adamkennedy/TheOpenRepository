package Perl::Dist::WiX::DirectoryTree;

#####################################################################
# Perl::Dist::WiX::DirectoryTree - Class containing initial tree of
#   <Directory> tag objects.
#
# Copyright 2009 Curtis Jewell
#
# License is the same as perl. See Wix.pm for details.
#
#<<<
use     5.006;
use     strict;
use     warnings;
use     vars                  qw( $VERSION                       );
use     Object::InsideOut     qw( Perl::Dist::WiX::Misc Storable );
use     Params::Util          qw( _IDENTIFIER _STRING            );
use     File::Spec::Functions qw( catdir                         );
require Perl::Dist::WiX::Directory;

use version; $VERSION = version->new('0.169')->numify;
#>>>
#####################################################################
# Accessors:
#   root: Returns the root of the directory tree created by new.

## no critic 'ProhibitUnusedVariables'
my @root : Field : Get(root);
my @app_dir : Field : Arg(Name => 'app_dir', Required => 1) : Get(app_dir);
my @app_name : Field : Arg(Name => 'app_name', Required => 1) :
  Get(app_name);

#####################################################################
# Constructor for DirectoryTree
#
# Parameters: [pairs]

sub _init : Init {
	my $self      = shift;
	my $object_id = ${$self};

	$root[$object_id] = Perl::Dist::WiX::Directory->new(
		id      => 'TARGETDIR',
		name    => 'SourceDir',
		special => 1,
	);

	return $self;
} ## end sub _init :

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
	my $self       = shift;
	my $params_ref = {@_};

	# Set defaults for parameters.
	$self->trace_line( 5,
		    "\$self: $self\n$params_ref: $params_ref\n"
		  . "path_to_find: $params_ref->{path_to_find}\n" );
	my $path_to_find = _STRING( $params_ref->{path_to_find} )
	  || PDWiX::Parameter->throw(
		parameter => 'path_to_find',
		where     => '::DirectoryTree->search_dir'
	  );
	my $descend = $params_ref->{descend} || 1;
	my $exact   = $params_ref->{exact}   || 0;

	return $self->root->search_dir(
		path_to_find => $path_to_find,
		descend      => $descend,
		exact        => $exact,
	);
} ## end sub search_dir

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
	my ( $self, @dirs ) = @_;

	$self->trace_line( 2, "Initializing directory tree.\n" );

	# Create starting directories.
	my $branch = $self->root->add_directory( {
			id      => 'INSTALLDIR',
			special => 2,
			path    => $self->app_dir,
		} );
	$self->root->add_directory( {
			id      => 'ProgramMenuFolder',
			special => 2
		}
	  )->add_directory( {
			id      => 'App_Menu',
			special => 1,
			name    => $self->app_name
		} );
#<<<
	$branch->add_directories_id(
		'Perl',      'perl',
		'Toolchain', 'c',
		'License',   'licenses',
		'Cpan',      'cpan',
		'Win32',     'win32',
	);
#>>>
	$branch->add_directories_init( qw(
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
		  perl\lib\Archive
		  perl\lib\B
		  perl\lib\CGI
		  perl\lib\Compress
		  perl\lib\CPAN
		  perl\lib\CPAN\API
		  perl\lib\CPANPLUS
		  perl\lib\CPANPLUS\Dist
		  perl\lib\CPANPLUS\Internals
		  perl\lib\Devel
		  perl\lib\Digest
		  perl\lib\ExtUtils
		  perl\lib\File
		  perl\lib\Filter
		  perl\lib\Filter\Util
		  perl\lib\Getopt
		  perl\lib\IO
		  perl\lib\IO\Compress
		  perl\lib\IO\Uncompress
		  perl\lib\IPC
		  perl\lib\Locale
		  perl\lib\Locale\Maketext
		  perl\lib\Log
		  perl\lib\Log\Message
		  perl\lib\Math
		  perl\lib\Math\BigInt
		  perl\lib\Module
		  perl\lib\Module\Build
		  perl\lib\Net
		  perl\lib\Pod
		  perl\lib\Term
		  perl\lib\Test
		  perl\lib\Test\Harness
		  perl\lib\Text
		  perl\lib\Thread
		  perl\lib\Tie
		  perl\lib\Time
		  perl\lib\Unicode
		  perl\lib\autodie
		  perl\lib\auto
		  perl\lib\auto\share
		  perl\lib\auto\Archive
		  perl\lib\auto\B
		  perl\lib\auto\Compress
		  perl\lib\auto\Devel
		  perl\lib\auto\Devel\PPPort
		  perl\lib\auto\Digest
		  perl\lib\auto\Digest\MD5
		  perl\lib\auto\Encode
		  perl\lib\auto\Encode\Byte
		  perl\lib\auto\Encode\CN
		  perl\lib\auto\Encode\EBCDIC
		  perl\lib\auto\Encode\JP
		  perl\lib\auto\Encode\KR
		  perl\lib\auto\Encode\Symbol
		  perl\lib\auto\Encode\TW
		  perl\lib\auto\Encode\Unicode
		  perl\lib\auto\ExtUtils
		  perl\lib\auto\File
		  perl\lib\auto\Filter
		  perl\lib\auto\Filter\Util
		  perl\lib\auto\Filter\Util\Call
		  perl\lib\auto\IO
		  perl\lib\auto\IO\Compress
		  perl\lib\auto\Math
		  perl\lib\auto\Math\BigInt
		  perl\lib\auto\Math\BigInt\FastCalc
		  perl\lib\auto\Module
		  perl\lib\auto\Module\Load
		  perl\lib\auto\PerlIO
		  perl\lib\auto\Pod
		  perl\lib\auto\POSIX
		  perl\lib\auto\Term
		  perl\lib\auto\Test
		  perl\lib\auto\Test\Harness
		  perl\lib\auto\Text
		  perl\lib\auto\Thread
		  perl\lib\auto\threads
		  perl\lib\auto\threads\shared
		  perl\lib\auto\Time
		  perl\lib\auto\XS
		  perl\site
		  perl\site\lib
		  perl\site\lib\Archive
		  perl\site\lib\Compress
		  perl\site\lib\Compress\Raw
		  perl\site\lib\Digest
		  perl\site\lib\File
		  perl\site\lib\HTML
		  perl\site\lib\IO
		  perl\site\lib\IO\Compress
		  perl\site\lib\IO\Compress\Adapter
		  perl\site\lib\IO\Uncompress
		  perl\site\lib\IO\Uncompress\Adapter
		  perl\site\lib\Term
		  perl\site\lib\Win32
		  perl\site\lib\Win32API
		  perl\site\lib\auto
		  perl\site\lib\auto\share
		  perl\site\lib\auto\Archive
		  perl\site\lib\auto\Compress
		  perl\site\lib\auto\Compress\Raw
		  perl\site\lib\auto\Digest
		  perl\site\lib\auto\File
		  perl\site\lib\auto\HTML
		  perl\site\lib\auto\IO
		  perl\site\lib\auto\IO\Compress
		  perl\site\lib\auto\Term
		  perl\site\lib\auto\Win32
		  perl\site\lib\auto\Win32API
		  ), @dirs
	);

	return $self;
} ## end sub initialize_tree

########################################
# add_root_directory($id, $dir)

sub add_root_directory {
	my ( $self, $id, $dir ) = @_;

	unless ( defined _IDENTIFIER($id) ) {
		PDWiX::Parameter->throw(
			parameter => 'id',
			where     => '::DirectoryTree->add_root_directory'
		);
	}

	unless ( defined _STRING($dir) ) {
		PDWiX::Parameter->throw(
			parameter => 'dir',
			where     => '::DirectoryTree->add_root_directory'
		);
	}

	my $path = $self->app_dir;

	$self->trace_line( 5, "Path: $path\n" );

	return $self->search_dir(
		path_to_find => $path,
		descend      => 0,
		exact        => 1,
	  )->add_directory( {
			id   => $id,
			name => $dir,
			path => catdir( $path, $dir ) } );
} ## end sub add_root_directory

########################################
# as_string
# Parameters:
#   None
# Returns:
#   String representation of the <Directory> tags this object contains.

sub as_string {
	my $self = shift;

	my $string = $self->root->as_string(1);

	return $string ne q{} ? $self->indent( 4, $string ) : q{};
}

1;
