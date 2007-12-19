package Perl::Dist::Inno;

use 5.005;
use strict;
use Carp                  'croak';
use Archive::Tar          ();
use Archive::Zip          ();
use File::Spec            ();
use File::Spec::Unix      ();
use File::Spec::Win32     ();
use File::Copy            ();
use File::Copy::Recursive ();
use File::Path            ();
use File::pushd           ();
use File::Remove          ();
use File::Basename        ();
use IPC::Run3             ();
use Params::Util          qw{ _STRING _HASH _INSTANCE };
use HTTP::Status          ();
use LWP::UserAgent        ();
use LWP::Online           ();
use Tie::File             ();

use base 'Perl::Dist::Inno::Script';

use vars qw{$VERSION};
BEGIN {
        $VERSION = '0.50';
}

use Object::Tiny qw{
	offline
	download_dir
	image_dir
	modules_dir
	license_dir
	build_dir
	iss_file
	remove_image
	user_agent
	cpan
	bin_perl
	bin_make
	bin_pexports
	bin_dlltool
	env_path
	env_lib
	env_include
	debug_stdout
	debug_stderr
};

use Perl::Dist::Inno                ();
use Perl::Dist::Asset               ();
use Perl::Dist::Asset::Binary       ();
use Perl::Dist::Asset::Library      ();
use Perl::Dist::Asset::Perl         ();
use Perl::Dist::Asset::Distribution ();
use Perl::Dist::Asset::Module       ();
use Perl::Dist::Asset::File         ();
use Perl::Dist::Util::Toolchain     ();





#####################################################################
# Constructor

sub new {
	my $class  = shift;
	my %params = @_;

	# Apply some defaults
	if ( defined $params{image_dir} and ! defined $params{default_dir_name} ) {
		$params{default_dir_name} = $params{image_dir};
	}
	if ( defined $params{temp_dir} ) {
		unless ( defined $params{download_dir} ) {
			$params{download_dir} = File::Spec->catdir(
				$params{temp_dir}, 'download',
			);
			File::Path::mkpath($params{download_dir});
		}
		unless ( defined $params{build_dir} ) {
			$params{build_dir} = File::Spec->catdir(
				$params{temp_dir}, 'build',
			);
			if ( -d $params{build_dir} ) {
				File::Remove::remove( \1, $params{build_dir} );
			}
			File::Path::mkpath($params{build_dir});
		}
		unless ( defined $params{output_dir} ) {
			$params{output_dir} = File::Spec->catdir(
				$params{temp_dir}, 'output',
			);
			if ( -d $params{output_dir} ) {
				File::Remove::remove( \1, $params{output_dir} );
			}
			File::Path::mkpath($params{output_dir});
		}
	}

	# Hand off to the parent class
	my $self = $class->SUPER::new(%params);

        # Apply more defaults
	unless ( defined $self->remove_image ) {
		$self->{remove_image} = 1;
	}
	unless ( defined $self->{trace} ) {
		$self->{trace} = 1;
	}
	unless ( defined $self->debug_stdout ) {
		$self->{debug_stdout} = File::Spec->catfile(
			$self->output_dir,
			'debug.out',
		);
	}
	unless ( defined $self->debug_stderr ) {
		$self->{debug_stderr} = File::Spec->catfile(
			$self->output_dir,
			'debug.err',
		);
	}

	# Auto-detect online-ness if needed
	unless ( defined $self->user_agent ) {
		$self->{user_agent} = LWP::UserAgent->new;
	}
	unless ( defined $self->offline ) {
		$self->{offline} = LWP::Online::offline();
	}

	# Normalize some params
	$self->{offline}      = !! $self->offline;
	$self->{trace}        = !! $self->{trace};
	$self->{remove_image} = !! $self->remove_image;

	# Check params
	unless ( _STRING($self->download_dir) ) {
		croak("Missing or invalid download_dir param");
	}
	unless ( defined $self->modules_dir ) {
		$self->{modules_dir} = File::Spec->catdir( $self->download_dir, 'modules' );
	}
	unless ( _STRING($self->modules_dir) ) {
		croak("Invalid modules_dir param");
	}
	unless ( _STRING($self->image_dir) ) {
		croak("Missing or invalid image_dir param");
	}
	unless ( defined $self->license_dir ) {
		$self->{license_dir} = File::Spec->catdir( $self->image_dir, 'licenses' );
	}
	unless ( _STRING($self->license_dir) ) {
		croak("Invalid license_dir param");
	}
	unless ( _STRING($self->build_dir) ) {
		croak("Missing or invalid build_dir param");
	}
	unless ( _INSTANCE($self->user_agent, 'LWP::UserAgent') ) {
		croak("Missing or invalid user_agent param");
	}
	unless ( _INSTANCE($self->cpan, 'URI') ) {
		croak("Missing or invalid cpan param");
	}
	unless ( $self->cpan->as_string =~ /\/$/ ) {
		croak("Missing trailing slash in cpan param");
	}
	unless ( defined $self->iss_file ) {
		$self->{iss_file} = File::Spec->catfile(
			$self->output_dir, $self->app_id . '.iss'
		);
	}

	# Clear the previous build
	if ( -d $self->image_dir ) {
		if ( $self->remove_image ) {
			$self->trace("Removing previous " . $self->image_dir . "\n");
			File::Remove::remove( \1, $self->image_dir );
		} else {
			croak("The image_dir directory already exists");
		}
	} else {
		$self->trace("No previous " . $self->image_dir . " found\n");
	}

	# Initialize the build
	for my $d (
		$self->download_dir,
		$self->image_dir,
		$self->modules_dir,
		$self->license_dir,
	) {
		next if -d $d;
		File::Path::mkpath($d);
	}

	# More details on the tracing
	if ( $self->{trace} ) {
		$self->{stdout} = undef;
		$self->{stderr} = undef;
	} else {
		$self->{stdout} = \undef;
		$self->{stderr} = \undef;
	}

	# Inno-Setup Initialization
	$self->{env_path}    = [];
	$self->{env_lib}     = [];
	$self->{env_include} = [];
	$self->add_dir('c');
	$self->add_dir('perl');
	$self->add_dir('licenses');
	$self->add_uninstall;
	$self->add_icon(
		name     => 'Perl Documentation',
		filename => 'perl\bin\perldoc',
	);

	# Set some common environment variables
	$self->add_env( TERM        => 'dumb' );
	$self->add_env( FTP_PASSIVE => 1      );

        return $self;
}

sub source_dir {
	$_[0]->image_dir;
}





#####################################################################
# Adding Inno-Setup Information

sub add_icon {
	my $self   = shift;
	my %params = @_;
	$params{name}     = "{group}\\$params{name}";
	unless ( $params{filename} =~ /^\{/ ) {
		$params{filename} = "{app}\\$params{filename}";
	}
	$self->SUPER::add_icon(%params);
}

sub add_env_path {
	my $self = shift;
	my @path = @_;
	my $dir = File::Spec->catdir(
		$self->image_dir, @path,
	);
	unless ( -d $dir ) {
		croak("PATH directory $dir does not exist");
	}
	push @{$self->{env_path}}, [ @path ];
	return 1;
}

sub get_env_path {
	my $self = shift;
	return join ';', map {
		File::Spec->catdir( $self->image_dir, @$_ )
	} @{$self->env_path};
}

sub get_inno_path {
	my $self = shift;
	return join ';', '{olddata}', map {
		File::Spec->catdir( '{app}', @$_ )
	} @{$self->env_path};
}

sub add_env_lib {
	my $self = shift;
	my @path = @_;
	my $dir = File::Spec->catdir(
		$self->image_dir, @path,
	);
	unless ( -d $dir ) {
		croak("INC directory $dir does not exist");
	}
	push @{$self->{env_lib}}, [ @path ];
	return 1;
}

sub get_env_lib {
	my $self = shift;
	return join ';', map {
		File::Spec->catdir( $self->image_dir, @$_ )
	} @{$self->env_lib};
}

sub get_inno_lib {
	my $self = shift;
	return join ';', '{olddata}', map {
		File::Spec->catdir( '{app}', @$_ )
	} @{$self->env_lib};
}

sub add_env_include {
	my $self = shift;
	my @path = @_;
	my $dir = File::Spec->catdir(
		$self->image_dir, @path,
	);
	unless ( -d $dir ) {
		croak("PATH directory $dir does not exist");
	}
	push @{$self->{env_include}}, [ @path ];
	return 1;
}

sub get_env_include {
	my $self = shift;
	return join ';', map {
		File::Spec->catdir( $self->image_dir, @$_ )
	} @{$self->env_include};
}

sub get_inno_include {
	my $self = shift;
	return join ';', '{olddata}', map {
		File::Spec->catdir( '{app}', @$_ )
	} @{$self->env_include};
}



#####################################################################
# Main Methods

sub install_c_toolchain {
	my $self = shift;

	# Install dmake
	$self->install_binary(
		name       => 'dmake',
		share      => 'Perl-Dist-Downloads dmake-4.8-20070327-SHAY.zip',
		license    => {
			'dmake/COPYING'            => 'dmake/COPYING',
			'dmake/readme/license.txt' => 'dmake/license.txt',
		},
		install_to => {
			'dmake/dmake.exe' => 'c/bin/dmake.exe',	
			'dmake/startup'   => 'c/bin/startup',
		},
	);

	# Initialize the make location
	$self->{bin_make} = File::Spec->catfile(
		$self->image_dir, 'c', 'bin', 'dmake.exe',
	);
	unless ( -x $self->bin_make ) {
		croak("Can't execute make");
	}

	# Install the compilers (gcc)
	$self->install_binary(
		name       => 'gcc-core',
		share      => 'Perl-Dist-Downloads gcc-core-3.4.5-20060117-1.tar.gz',
		license    => {
			'COPYING'     => 'gcc/COPYING',
			'COPYING.lib' => 'gcc/COPYING.lib',
		},
		install_to => 'c',
	);
	$self->install_binary(
		name       => 'gcc-g++',
		share      => 'Perl-Dist-Downloads gcc-g++-3.4.5-20060117-1.tar.gz',
		install_to => 'c',
	);

	# Install the binary utilities
	$self->install_binary(
		name       => 'mingw-make',
		share      => 'Perl-Dist-Downloads mingw32-make-3.81-2.tar.gz',
		install_to => 'c',
	);

	$self->install_binary(
		name       => 'binutils',
		share      => 'Perl-Dist-Downloads binutils-2.17.50-20060824-1.tar.gz',
		license    => {
			'Copying'     => 'binutils/Copying',
			'Copying.lib' => 'binutils/Copying.lib',
		},
		install_to => 'c',
	);
	$self->{bin_dlltool} = File::Spec->catfile(
		$self->image_dir, 'c', 'bin', 'dlltool.exe',
	);
	unless ( -x $self->bin_dlltool ) {
		die "Can't execute dlltool";
	}

	$self->install_binary(
		name       => 'pexports',
		share      => 'Perl-Dist-Downloads pexports-0.43-1.zip',
		license    => {
			'pexports-0.43/COPYING' => 'pexports/COPYING',
		},
		install_to => {
			'pexports-0.43/bin' => 'c/bin',
		},
	);
	$self->{bin_pexports} = File::Spec->catfile(
		$self->image_dir, 'c', 'bin', 'pexports.exe',
	);
	unless ( -x $self->bin_pexports ) {
		die "Can't execute pexports";
	}

	# Install support libraries
	$self->install_binary(
		name       => 'mingw-runtime',
		share      => 'Perl-Dist-Downloads mingw-runtime-3.13.tar.gz',
		license    => {
			'doc/mingw-runtime/Contributors' => 'mingw/Contributors',
			'doc/mingw-runtime/Disclaimer'   => 'mingw/Disclaimer',
		},
		install_to => 'c',
	);
	$self->install_binary(
		name       => 'w32api',
		share      => 'Perl-Dist-Downloads w32api-3.10.tar.gz',
		install_to => 'c',
	);
	$self->install_file(
		share      => 'Perl-Dist README.w32api',
		install_to => 'licenses\win32api\README.w32api',
	);

	# Set up the environment variables for the binaries
	$self->add_env_path(    'c', 'bin'     );
	$self->add_env_lib(     'c', 'lib'     );
	$self->add_env_include( 'c', 'include' );

	return 1;
}

sub install_c_libraries {
	my $self = shift;
	$self->install_zlib;
	$self->install_libiconv;
	$self->install_libxml;
	return 1;
}

sub install_perl {
	my $self = shift;

	# By default, install Perl 5.8.8
	$self->install_perl_588(
		name       => 'perl',
		share      => 'Perl-Dist-Downloads perl-5.8.8.tar.gz',
		unpack_to  => 'perl',
		patch      => {
			'Install.pm'   => 'lib\ExtUtils\Install.pm',
			'Installed.pm' => 'lib\ExtUtils\Installed.pm',
			'Packlist.pm'  => 'lib\ExtUtils\Packlist.pm',
		},
		install_to => 'perl',
		license    => {
			'perl-5.8.8/Readme'   => 'perl/Readme',
			'perl-5.8.8/Artistic' => 'perl/Artistic',
			'perl-5.8.8/Copying'  => 'perl/Copying',
		},
	);

	return 1;
}

sub remove_waste {
	my $self = shift;
	$self->trace("Removing doc, man, info and html documentation...\n");
	File::Remove::remove( \1, $self->_dir('perl', 'man')     );
	File::Remove::remove( \1, $self->_dir('perl', 'html')    );
	File::Remove::remove( \1, $self->_dir('c',    'man')     );
	File::Remove::remove( \1, $self->_dir('c',    'doc')     );
	File::Remove::remove( \1, $self->_dir('c',    'info')    );
	$self->trace("Removing C library manifests...\n");
	File::Remove::remove( \1, $self->_dir('c', 'manifest')   );
	$self->trace("Removing CPAN build directories and download caches...\n");
	File::Remove::remove( \1, $self->_dir('cpan', 'sources') );
	File::Remove::remove( \1, $self->_dir('cpan', 'build')   );
	return 1;
}





#####################################################################
# Perl 5.8.8 Support

sub install_perl_588 {
	my $self = shift;

	# Install the main perl distributions
	$self->install_perl_588_bin(
		name       => 'perl',
		dist       => 'NWCLARK/perl-5.8.8.tar.gz',
		unpack_to  => 'perl',
		patch      => {
			'ExtUtils_Install588.pm'   => 'lib\ExtUtils\Install.pm',
			'ExtUtils_Installed588.pm' => 'lib\ExtUtils\Installed.pm',
			'ExtUtils_Packlist588.pm'  => 'lib\ExtUtils\Packlist.pm',
		},
		license    => {
			'perl-5.8.8/Readme'   => 'perl/Readme',
			'perl-5.8.8/Artistic' => 'perl/Artistic',
			'perl-5.8.8/Copying'  => 'perl/Copying',
		},
		install_to => 'perl',
	);

	# Upgrade the toolchain modules
	$self->install_perl_588_toolchain;

	return 1;
}

sub install_perl_588_bin {
	my $self = shift;
	my $perl = Perl::Dist::Asset::Perl->new(
		cpan => $self->cpan,
		@_,
	);
	unless ( $self->bin_make ) {
		croak("Cannot build Perl yet, no bin_make defined");
	}

	# Download the file
	my $tgz = $self->_mirror( 
		$perl->url,
		$self->download_dir,
	);

	# Unpack to the build directory
	my $unpack_to = File::Spec->catdir( $self->build_dir, $perl->unpack_to );
	if ( -d $unpack_to ) {
		$self->trace("Removing previous $unpack_to\n");
		File::Remove::remove( \1, $unpack_to );
	}
	$self->_extract( $tgz => $unpack_to );

	# Get the versioned name of the directory
	(my $perlsrc = $tgz) =~ s{\.tar\.gz\z|\.tgz\z}{};
	$perlsrc = File::Basename::basename($perlsrc);

	# Pre-copy updated files over the top of the source
	my $patch = $perl->patch;
	if ( $patch ) {
		foreach my $f ( sort keys %$patch ) {
			my $from = File::ShareDir::module_file( 'Perl::Dist', $f );
			my $to   = File::Spec->catfile(
				$unpack_to, $perlsrc, $patch->{$f},
			);
			$self->_copy( $from => $to );
		}
	}

	# Copy in licenses
	if ( ref $perl->license eq 'HASH' ) {
		my $license_dir = File::Spec->catdir( $self->image_dir, 'licenses' );
		$self->_extract_filemap( $tgz, $perl->license, $license_dir, 1 );
	}

	# Build win32 perl
	SCOPE: {
		my $wd = File::pushd::pushd(
			File::Spec->catdir( $unpack_to, $perlsrc , "win32" ),
		);

		# Prepare to patch
		my $image_dir    = $self->image_dir;
		my $perl_install = File::Spec->catdir( $self->image_dir, $perl->install_to );
		my (undef,$short_install) = File::Spec->splitpath( $perl_install, 1 );
		$self->trace("Patching makefile.mk\n");
		tie my @makefile, 'Tie::File', 'makefile.mk'
			or die "Couldn't read makefile.mk";
		for ( @makefile ) {
			if ( m{\AINST_TOP\s+\*=\s+} ) {
				s{\\perl}{$short_install}; # short has the leading \

			} elsif ( m{\ACCHOME\s+\*=} ) {
				s{c:\\mingw}{$image_dir\\c}i;

			} else {
				next;
			}
		}
		untie @makefile;

		$self->trace("Building perl...\n");
		$self->_make;

		SCOPE: {
			local $ENV{PERL_SKIP_TTY_TEST} = 1;
			$self->trace("Testing perl build\n");
			$self->_make('test') if 0;
		}

		$self->trace("Installing perl...\n");
		$self->_make( qw/install UNINST=1/ );
	}

	# Should now have a perl to use
	$self->{bin_perl} = File::Spec->catfile( $self->image_dir, qw/perl bin perl.exe/ );
	unless ( -x $self->bin_perl ) {
		die "Can't execute " . $self->bin_perl;
	}

	# Add to the environment variables
	$self->add_env_path( 'perl', 'bin' );
	$self->add_env_lib(  'perl', 'bin' );
	$self->add_env_include( 'perl', 'lib', 'CORE' );

	return 1;
}

# Resolve the distribution list at startup time
my $toolchain = Perl::Dist::Util::Toolchain->new( qw{
	ExtUtils::MakeMaker
	File::Path
	ExtUtils::Command
	Win32API::File
	ExtUtils::Install
	ExtUtils::Manifest
	Test::Harness
	Test::Simple
	ExtUtils::CBuilder
	ExtUtils::ParseXS
	version
	Scalar::Util
	IO::Compress::Base
	Compress::Raw::Zlib
	Compress::Raw::Bzip2
	IO::Compress::Zip
	IO::Compress::Bzip2
	Compress::Zlib
	Compress::Bzip2
	IO::Zlib
	File::Spec
	File::Temp
	Win32API::Registry
	Win32::TieRegistry
	File::HomeDir
	File::Which
	Archive::Zip
	Archive::Tar
	YAML
	Net::FTP
	Digest::MD5
	Digest::SHA1
	Digest::SHA
	Module::Build
	Term::Cap
	CPAN
	Term::ReadLine::Perl
} );

# Get the regular Perl to generate the list.
# Run it in a separate process so we don't hold
# any permanent CPAN.pm locks (for now).
$toolchain->delegate;
if ( $toolchain->{errstr} ) {
	die "Failed to generate toolchain distributions";
}

sub install_perl_588_toolchain {
	my $self = shift;

	foreach my $dist ( @{$toolchain->{dists}} ) {
		my $force             = 0;
		my $automated_testing = 0;
		if ( $dist =~ /Scalar-List-Util/ ) {
			# Does something weird with tainting
			$force = 1;
		}
		if ( $dist =~ /File-Temp/ ) {
			# Lock tests break
			$force = 1;
		}
		if ( $dist =~ /Term-ReadLine-Perl/ ) {
			# Does evil things when testing, and
			# so testing cannot be automated.
			$automated_testing = 1;
		}
		$self->install_distribution(
			name              => $dist,
			force             => $force,
			automated_testing => $automated_testing,
		);
	}

	# With the toolchain we need in place, install the default
	# configuation.
	$self->install_file(
		share      => 'Perl-Dist CPAN_Config.pm',
		install_to => 'perl/lib/CPAN/Config.pm',
	);

	return 1;
}





#####################################################################
# Perl 5.10.0 Support

sub install_perl_5100 {
	my $self = shift;

	# Install the main binary
	$self->install_perl_5100_bin(
		name       => 'perl',
		dist       => 'RGARCIA/perl-5.10.0-RC2.tar.gz',
		unpack_to  => 'perl',
		license    => {
			'perl-5.10.0/Readme'   => 'perl/Readme',
			'perl-5.10.0/Artistic' => 'perl/Artistic',
			'perl-5.10.0/Copying'  => 'perl/Copying',
		},
		install_to => 'perl',
		# force      => 1,
	);

	# Install the toolchain
	$self->install_perl_5100_toolchain;

	return 1;
}

sub install_perl_5100_bin {
	my $self = shift;
	my $perl = Perl::Dist::Asset::Perl->new(
		cpan => $self->cpan,
		@_,
	);
	unless ( $self->bin_make ) {
		croak("Cannot build Perl yet, no bin_make defined");
	}
	$self->trace("Preparing " . $perl->name . "\n");

	# Download the file
	my $tgz = $self->_mirror(
		$perl->url,
		$self->download_dir,
	);

	# Unpack to the build directory
	my $unpack_to = File::Spec->catdir( $self->build_dir, $perl->unpack_to );
	if ( -d $unpack_to ) {
		$self->trace("Removing previous $unpack_to\n");
		File::Remove::remove( \1, $unpack_to );
	}
	$self->_extract( $tgz => $unpack_to );

	# Get the versioned name of the directory
	(my $perlsrc = $tgz) =~ s{\.tar\.gz\z|\.tgz\z}{};
	$perlsrc = File::Basename::basename($perlsrc);

	# Pre-copy updated files over the top of the source
	my $patch = $perl->patch;
	if ( $patch ) {
		foreach my $f ( sort keys %$patch ) {
			my $from = File::ShareDir::module_file( 'Perl::Dist', $f );
			my $to   = File::Spec->catfile(
				$unpack_to, $perlsrc, $patch->{$f},
			);
			$self->_copy( $from => $to );
		}
	}

	# Copy in licenses
	if ( ref $perl->license eq 'HASH' ) {
		my $license_dir = File::Spec->catdir( $self->image_dir, 'licenses' );
		$self->_extract_filemap( $tgz, $perl->license, $license_dir, 1 );
	}

	# Build win32 perl
	SCOPE: {
		my $wd = File::pushd::pushd(
			File::Spec->catdir( $unpack_to, $perlsrc , "win32" ),
		);

		# Prepare to patch
		my $image_dir    = $self->image_dir;
		my $perl_install = File::Spec->catdir( $self->image_dir, $perl->install_to );
		my ($vol,$short_install) = File::Spec->splitpath( $perl_install, 1 );
		SCOPE: {
			$self->trace("Patching makefile.mk\n");

			# Read in the makefile
			local *MAKEFILE;
			local $/ = undef;
			open( MAKEFILE, 'makefile.mk' ) or die "open: $!";
			my $makefile_mk = <MAKEFILE>;
			$makefile_mk =~ s/(?:\015{1,2}\012|\015|\012)/\n/sg;
			close MAKEFILE;

			# Apply the changes
			$makefile_mk =~ s/^(INST_DRV\s+\*=\s+).+?(\n)/$1$vol$2/m;
			$makefile_mk =~ s/^(INST_TOP\s+\*=\s+).+?(\n)/$1$perl_install$2/m;
			$makefile_mk =~ s/C\:\\MinGW/$image_dir\\c/;

			# Write out the makefile
			open( MAKEFILE, '>makefile.mk' ) or die "open: $!";
			print MAKEFILE $makefile_mk;
			close MAKEFILE;
		}

		$self->trace("Building perl...\n");
		$self->_make;

		unless ( $perl->force ) {
			local $ENV{PERL_SKIP_TTY_TEST} = 1;
			$self->trace("Testing perl build\n");
			$self->_make('test');
		}

		$self->trace("Installing perl...\n");
		$self->_make( 'install' );
	}

	# Should now have a perl to use
	$self->{bin_perl} = File::Spec->catfile( $self->image_dir, qw/perl bin perl.exe/ );
	unless ( -x $self->bin_perl ) {
		die "Can't execute " . $self->bin_perl;
	}

	# Add to the environment variables
	$self->add_env_path( 'perl', 'bin' );
	$self->add_env_lib(  'perl', 'bin' );
	$self->add_env_include( 'perl', 'lib', 'CORE' );

	return 1;
}

sub install_perl_5100_toolchain {
	my $self = shift;

	return 1;
}





#####################################################################
# Install C Libraries

sub install_zlib {
	my $self = shift;

	# Zlib is a pexport-based lib-install
	$self->install_library(
		name       => 'zlib',
		share      => 'Perl-Dist-Downloads zlib-1.2.3.win32.zip',
		unpack_to  => 'zlib',
		build_a    => {
			'dll'    => 'zlib-1.2.3.win32/bin/zlib1.dll',
			'def'    => 'zlib-1.2.3.win32/bin/zlib1.def',
			'a'      => 'zlib-1.2.3.win32/lib/zlib1.a',
		},
		install_to => {
			'zlib-1.2.3.win32/bin'     => 'c/bin',
			'zlib-1.2.3.win32/lib'     => 'c/lib',
			'zlib-1.2.3.win32/include' => 'c/include',
		},
	);

	return 1;
}

sub install_libiconv {
	my $self = shift;

	# libiconv for win32 comes in 3 parts, install them.
	$self->install_binary(
		name       => 'iconv-dep',
		share      => 'Perl-Dist-Downloads libiconv-1.9.2-1-dep.zip',
		install_to => 'c',
	);
	$self->install_binary(
		name       => 'iconv-lib',
		share      => 'Perl-Dist-Downloads libiconv-1.9.2-1-lib.zip',
		install_to => 'c',
	);
	$self->install_binary(
		name       => 'iconv-bin',
		share      => 'Perl-Dist-Downloads libiconv-1.9.2-1-bin.zip',
		install_to => 'c',
	);

	# The dll is installed with an unexpected name,
	# so we correct it post-install.
	$self->_move(
		File::Spec->catfile( $self->image_dir, 'c', 'bin', 'libiconv2.dll' ),
		File::Spec->catfile( $self->image_dir, 'c', 'bin', 'iconv.dll'     ),
	);

	return 1;
}

sub install_libxml {
	my $self = shift;

	# libxml is a straight forward pexport-based install
	$self->install_library(
		name       => 'libxml2',
		share      => 'Perl-Dist-Downloads libxml2-2.6.30.win32.zip',
		unpack_to  => 'libxml2',
		build_a    => {
			'dll'    => 'libxml2-2.6.30.win32/bin/libxml2.dll',
			'def'    => 'libxml2-2.6.30.win32/bin/libxml2.def',
			'a'      => 'libxml2-2.6.30.win32/lib/libxml2.a',
		},			
		install_to => {
			'libxml2-2.6.30.win32/bin'     => 'c/bin',
			'libxml2-2.6.30.win32/lib'     => 'c/lib',
			'libxml2-2.6.30.win32/include' => 'c/include',
		},
	);

	return 1;
}





#####################################################################
# Generic Installation Methods

sub install_binary {
	my $self   = shift;
	my $binary = Perl::Dist::Asset::Binary->new(@_);
	my $name   = $binary->name;
	$self->trace("Preparing $name\n");

	# Download the file
	my $tgz = $self->_mirror(
		$binary->url,
		$self->download_dir,
	);

	# Unpack the archive
	my $install_to = $binary->install_to;
	if ( ref $binary->install_to eq 'HASH' ) {
		$self->_extract_filemap( $tgz, $binary->install_to, $self->image_dir );

	} elsif ( ! ref $binary->install_to ) {
		# unpack as a whole
		my $tgt = File::Spec->catdir( $self->image_dir, $binary->install_to );
		$self->_extract( $tgz => $tgt );

	} else {
		die "didn't expect install_to to be a " . ref $binary->install_to;
	}

	# Find the licenses
	if ( ref $binary->license eq 'HASH' )   {
		$self->_extract_filemap( $tgz, $binary->license, $self->license_dir, 1 );
	}

	return 1;
}

sub install_library {
	my $self    = shift;
	my $library = Perl::Dist::Asset::Library->new(
		cpan => $self->cpan,
		@_,
	);
	my $name = $library->name;
	$self->trace("Preparing $name\n");

	# Download the file
	my $tgz = $self->_mirror(
		$library->url,
		$self->download_dir,
	);

	# Unpack to the build directory
	my $unpack_to = File::Spec->catdir( $self->build_dir, $library->unpack_to );
	if ( -d $unpack_to ) {
		$self->trace("Removing previous $unpack_to\n");
		File::Remove::remove( \1, $unpack_to );
	}
	$self->_extract( $tgz => $unpack_to );

	# Build the .a file if needed
	if ( _HASH($library->build_a) ) {
		# Hand off for the .a generation
		$self->_dll_to_a(
			$library->build_a->{source} ?
			(
				source => File::Spec->catfile(
					$unpack_to, $library->build_a->{source},
				),
			) : (),
			dll    => File::Spec->catfile(
				$unpack_to, $library->build_a->{dll},
			),
			def    => File::Spec->catfile(
				$unpack_to, $library->build_a->{def},
			),
			a      => File::Spec->catfile(
				$unpack_to, $library->build_a->{a},
			),
		);
	}

	# Copy in the files
	my $install_to = $library->install_to;
	if ( _HASH($install_to) ) {
		foreach my $k ( sort keys %$install_to ) {
			my $from = File::Spec->catdir(
				$unpack_to, $k,
			);
			my $to = File::Spec->catdir(
				$self->image_dir, $install_to->{$k},
			);
			$self->_copy( $from => $to );
		}
	}

	# Copy in licenses
	if ( _HASH($library->license) ) {
		my $license_dir = File::Spec->catdir( $self->image_dir, 'licenses' );
		$self->_extract_filemap( $tgz, $library->license, $license_dir, 1 );
	}

	# Copy in the files
	

	return 1;
}


sub install_distribution {
	my $self = shift;
	my $dist = Perl::Dist::Asset::Distribution->new(
		cpan => $self->cpan,
		@_,
	);

	# Download the file
	my $tgz = $self->_mirror( 
		$dist->abs_uri( $self->cpan ),
		$self->download_dir,
	);

	# Where will it get extracted to
	my $dist_path = $dist->name;
	$dist_path =~ s/\.tar\.gz//;
	$dist_path =~ s/\.zip//;
	$dist_path =~ s/.+\///;
	my $unpack_to = File::Spec->catdir( $self->build_dir, $dist_path );

	# Extract the tarball
	if ( -d $unpack_to ) {
		$self->trace("Removing previous $unpack_to\n");
		File::Remove::remove( \1, $unpack_to );
	}
	$self->_extract( $tgz => $self->build_dir );
	unless ( -d $unpack_to ) {
		croak("Failed to extract $unpack_to");
	}

	# Build the module
	SCOPE: {
		my $wd = File::pushd::pushd( $unpack_to );

		# Enable automated_testing mode if needed
		# Blame Term::ReadLine::Perl for needing this ugly hack.
		if ( $dist->automated_testing ) {
			$self->trace("Installing with AUTOMATED_TESTING enabled...\n");
		}
		local $ENV{AUTOMATED_TESTING} = $dist->automated_testing ? 1 : '';

		$self->trace("Configuring " . $dist->name . "...\n");
		$self->_perl( 'Makefile.PL' );

		$self->trace("Building " . $dist->name . "...\n");
		$self->_make;

		unless ( $dist->force ) {
			$self->trace("Testing " . $dist->name . "\n");
			$self->_make('test');
		}

		$self->trace("Installing " . $dist->name . "...\n");
		$self->_make( qw/install UNINST=1/ );
	}

	return 1;
}

sub install_module {
	my $self   = shift;
	my $module = Perl::Dist::Asset::Module->new(
		cpan => $self->cpan,
		@_,
	);
	my $name   = $module->name;
	my $force  = $module->force;
	unless ( $self->bin_perl ) {
		croak("Cannot install CPAN modules yet, perl is not installed");
	}

	# Generate the CPAN installation script
	my $env_lib     = $self->get_env_lib;
	my $env_include = $self->get_env_include;
	my $cpan_str    = <<"END_PERL";
print "Installing $name from CPAN...\n";
my \$module = CPAN::Shell->expandany( "$name" ) 
	or die "CPAN.pm couldn't locate $name";
if ( \$module->uptodate ) {
	print "$name is up to date\n";
	exit(0);
}
print "\\\$ENV{PATH}    = '\$ENV{PATH}'\n";
print "\\\$ENV{LIB}     = '\$ENV{LIB}'\n";
print "\\\$ENV{INCLUDE} = '\$ENV{INCLUDE}'\n";
if ( $force ) {
	local \$ENV{PERL_MM_USE_DEFAULT} = 1;
	\$module->force("install");
	\$CPAN::DEBUG=1;
	unless ( \$module->uptodate ) {
		die "Forced installation of $name appears to have failed";
	}
} else {
	local \$ENV{PERL_MM_USE_DEFAULT} = 1;
	CPAN::Shell->install('$name');
	print "Completed install of $name\n";
	unless ( \$module->uptodate ) {
		die "Installation of $name appears to have failed";
	}
}
exit(0);
END_PERL

	# Execute the CPAN installation script
	$self->trace("Running install of $name\n");
	$self->_run3( $self->bin_perl, "-MCPAN", "-e", $cpan_str )
		or die "perl -MCPAN -e failed";
	die "Failure detected installing $name, stopping" if $?;

	return 1;
}

sub install_file {
	my $self = shift;
	my $dist = Perl::Dist::Asset::File->new(
		cpan => $self->cpan,
		@_,
	);

	# Get the file
	my $tgz = $self->_mirror(
		$dist->url,
		$self->download_dir
	);

	# Copy the file to the target location
	my $from = File::Spec->catfile( $self->download_dir, $dist->file       );
	my $to   = File::Spec->catfile( $self->image_dir,    $dist->install_to );
	$self->_copy( $from => $to );	

	# Clear the download file
	File::Remove::remove( \1, $tgz );

	return 1;
}





#####################################################################
# Package Generation

sub write_exe {
	my $self = shift;

	# Convert the environment to registry entries
	if ( @{$self->{env_path}} ) {
		my $value = "{olddata}";
		foreach my $array ( @{$self->{env_path}} ) {
			$value .= File::Spec::Win32->catdir(
				';{app}', @$array,
			);
		}
		$self->add_env( PATH => $value );
	}
	if ( @{$self->{env_lib}} ) {
		my $value = "{olddata}";
		foreach my $array ( @{$self->{env_lib}} ) {
			$value .= File::Spec::Win32->catdir(
				';{app}', @$array,
			);
		}
		$self->add_env( LIB => $value );
	}
	if ( @{$self->{env_include}} ) {
		my $value = "{olddata}";
		foreach my $array ( @{$self->{env_include}} ) {
			$value .= File::Spec::Win32->catdir(
				';{app}', @$array,
			);
		}
		$self->add_env( INCLUDE => $value );
	}

	$self->SUPER::write_exe(@_);
}

sub write_iss {
	my $self = shift;
	my $file = $self->iss_file;
	my $iss  = $self->as_string;
	open( ISS, ">$file" ) or croak("Failed to open ISS file to write");
	print ISS $iss;
	close ISS;
	return $file;
}

sub write_zip {
	my $self = shift;
	my $file = File::Spec->catfile(
		$self->output_dir, $self->output_base_filename . '.zip'
	);
	$self->trace("Generating zip at $file\n");

	# Create the archive
	my $zip = Archive::Zip->new;

	# Add the image directory to the root
	$zip->addTree( $self->image_dir, '' );

	# Write out the file name
	$zip->writeToFileNamed( $file );

	return $file;
}





#####################################################################
# Support Methods

sub trace {
	my $self = shift;
	if ( $self->{trace} ) {
		print $_[0];
	}
	return 1;
}

sub _dir {
	File::Spec->catdir( shift->image_dir, @_ );
}

sub _mirror {
	my ($self, $url, $dir) = @_;
	my $file = $url;
	$file =~ s|.+\/||;
	my $target = File::Spec->catfile( $dir, $file );
	if ( $self->offline and -f $target ) {
		return $target;
	}
	if ( $self->offline and ! $url =~ m|^file://| ) {
		$self->trace("Error: Currently offline, cannot download.\n");
		exit(0);
	}
	File::Path::mkpath($dir);
	$| = 1;

	$self->trace("Downloading $file...\n");
	my $ua = LWP::UserAgent->new;
	my $r  = $ua->mirror( $url, $target );
	if ( $r->is_error ) {
		$self->trace("    Error getting $url:\n" . $r->as_string . "\n");

	} elsif ( $r->code == HTTP::Status::RC_NOT_MODIFIED ) {
		$self->trace("(already up to date)\n");

	}

	return $target;
}

sub _copy {
	my ($self, $from, $to) = @_;
	my $basedir = File::Basename::dirname( $to );
	File::Path::mkpath($basedir) unless -e $basedir;
	$self->trace("Copying $from to $to\n");
	File::Copy::Recursive::rcopy( $from, $to ) or die $!;
}

sub _move {
	my ($self, $from, $to) = @_;
	my $basedir = File::Basename::dirname( $to );
	File::Path::mkpath($basedir) unless -e $basedir;
	$self->trace("Moving $from to $to\n");
	File::Copy::Recursive::rmove( $from, $to ) or die $!;
}

sub _make {
	my $self   = shift;
	my @params = @_;
	$self->trace(join(' ', '>', $self->bin_make, @params) . "\n");
	$self->_run3( $self->bin_make, @params ) or die "make failed";
	die "make failed (OS error)" if ( $? >> 8 );
	return 1;
}

sub _perl {
	my $self   = shift;
	my @params = @_;
	$self->trace(join(' ', '>', $self->bin_perl, @params) . "\n");
	$self->_run3( $self->bin_perl, @params ) or die "perl failed";
	die "perl failed (OS error)" if ( $? >> 8 );
	return 1;
}

sub _run3 {
	my $self = shift;
	local $ENV{PERL5LIB} = '';
	local $ENV{INCLUDE}  = $self->get_env_include;
	local $ENV{LIB}      = $self->get_env_lib;
	local $ENV{PATH}     = $self->get_env_path . ';' . $ENV{PATH};
	return IPC::Run3::run3( [ @_ ],
		\undef,
		$self->debug_stdout,
		$self->debug_stderr,
	);
}

sub _extract {
	my ( $self, $from, $to ) = @_;
	File::Path::mkpath($to);
	my $wd = File::pushd::pushd( $to );
	$|++;
	$self->trace("Extracting $from...\n");
	if ( $from =~ m{\.zip\z} ) {
		my $zip = Archive::Zip->new( $from );
		$zip->extractTree();

	} elsif ( $from =~ m{\.tar\.gz|\.tgz} ) {
		local $Archive::Tar::CHMOD = 0;
		Archive::Tar->extract_archive($from, 1);

	} else {
		die "Didn't recognize archive type for $from";
	}
	return 1;
}


sub _extract_filemap {
	my ( $self, $archive, $filemap, $basedir, $file_only ) = @_;

	if ( $archive =~ m{\.zip\z} ) {
		my $zip = Archive::Zip->new( $archive );
		my $wd = File::pushd::pushd( $basedir );
		while ( my ($f, $t) = each %$filemap ) {
			$self->trace("Extracting $f to $t\n");
			my $dest = File::Spec->catfile( $basedir, $t );
			$zip->extractTree( $f, $dest );
		}

	} elsif ( $archive =~ m{\.tar\.gz|\.tgz} ) {
		local $Archive::Tar::CHMOD = 0;
		my $tar = Archive::Tar->new( $archive );
		for my $file ( $tar->get_files ) {
			my $f = $file->full_path;
			my $canon_f = File::Spec::Unix->canonpath( $f );
			for my $tgt ( keys %$filemap ) {
				my $canon_tgt = File::Spec::Unix->canonpath( $tgt );
				my $t;

				# say "matching $canon_f vs $canon_tgt";
				if ( $file_only ) {
					next unless $canon_f =~ m{\A([^/]+[/])?\Q$canon_tgt\E\z}i;
					($t = $canon_f)   =~ s{\A([^/]+[/])?\Q$canon_tgt\E\z}
	             				{$filemap->{$tgt}}i;

				} else {
					next unless $canon_f =~ m{\A([^/]+[/])?\Q$canon_tgt\E}i;
					($t = $canon_f) =~ s{\A([^/]+[/])?\Q$canon_tgt\E}
	             				{$filemap->{$tgt}}i;
				}
				my $full_t = File::Spec->catfile( $basedir, $t );
				$self->trace("Extracting $f to $full_t\n");
				$tar->extract_file( $f, $full_t );
			}
		}

	} else {
		die "Didn't recognize archive type for $archive";
	}

	return 1;
}

# Convert a .dll to an .a file
sub _dll_to_a {
	my $self   = shift;
	my %params = @_;
	unless ( $self->bin_dlltool ) {
		croak("Required method bin_dlltool is not defined");
	}

	# Source file
	my $source = $params{source};
	if ( $source and ! $source =~ /\.dll$/ ) {
		croak("Missing or invalid source param");
	}

	# Target .dll file
	my $dll = $params{dll};
	unless ( $dll and $dll =~ /\.dll/ ) {
		croak("Missing or invalid .dll file");
	}

	# Target .def file
	my $def = $params{def};
	unless ( $def and $def =~ /\.def$/ ) {
		croak("Missing or invalid .def file");
	}

	# Target .a file
	my $_a = $params{a};
	unless ( $_a and $_a =~ /\.a$/ ) {
		croak("Missing or invalid .a file");
	}

	# Step 1 - Copy the source .dll to the target if needed
	unless ( ($source and -f $source) or -f $dll ) {
		croak("Need either a source or dll param");
	}
	if ( $source ) {
		$self->_move( $source => $dll );
	}

	# Step 2 - Generate the .def from the .dll
	SCOPE: {
		my $bin = $self->bin_pexports;
		unless ( $bin ) {
			croak("Required method bin_pexports is not defined");
		}
		my $ok = ! system("$bin $dll > $def");
		unless ( $ok and -f $def ) {
			croak("Failed to generate .def file");
		}
	}

	# Step 3 - Generate the .a from the .def
	SCOPE: {
		my $bin = $self->bin_dlltool;
		unless ( $bin ) {
			croak("Required method bin_dlltool is not defined");
		}
		my $ok = ! system("$bin -dllname $dll --def $def --output-lib $_a");
		unless ( $ok and -f $_a ) {
			croak("Failed to generate .a file");
		}
	}

	return 1;
}

1;
