package Perl::Dist::WiX;

=pod

=begin readme text

Perl-Dist-WiX version 1.100

=end readme

=for readme stop

=head1 NAME

Perl::Dist::WiX - 4th generation Win32 Perl distribution builder

=head1 VERSION

This document describes Perl::Dist::WiX version 1.000.

=for readme continue

=head1 DESCRIPTION

This package is the upgrade to Perl::Dist based on Windows Installer XML 
technology, instead of Inno Setup.

Perl distributions built with this module have the option of being created
as Windows Installer databases (otherwise known as .msi files)

=begin readme

=head1 INSTALLATION

To install this module, run the following commands:

	perl Makefile.PL
	make
	make test
	make install

=end readme

=for readme stop

=head1 SYNOPSIS

	# Sets up a distribution with the following options
	my $distribution = Perl::Dist::WiX->new(
		msi               => 1,
		trace             => 1,
		build_number      => 1,
		cpan              => URI->new(('file://C|/minicpan/')),
		image_dir         => 'C:\myperl',
		download_dir      => 'C:\cpandl',
		output_dir        => 'C:\myperl_build',
		temp_dir          => 'C:\temp',
		app_id            => 'myperl',
		app_name          => 'My Perl',
		app_publisher     => 'My Perl Distribution Project',
		app_publisher_url => 'http://test.invalid/',
	);

	# Creates the distribution
	$distribution->run();

=head1 INTERFACE

=cut

#<<<
use     5.008001;
use     Moose 0.90;
use     parent                qw( Perl::Dist::WiX::BuildPerl
                                  Perl::Dist::WiX::Checkpoint
                                  Perl::Dist::WiX::Libraries
                                  Perl::Dist::WiX::Installation
                                  Perl::Dist::WiX::ReleaseNotes );
use     Alien::WiX            qw( :ALL                          );
use     Archive::Zip          qw( :ERROR_CODES                  );
use     English               qw( -no_match_vars                );
use     List::MoreUtils       qw( any none uniq                 );
use     Params::Util          qw( 
	_HASH _STRING _INSTANCE _IDENTIFIER _ARRAY0 _ARRAY     
);
use     Readonly              qw( Readonly                      );
use     Storable              qw( retrieve                      );
use     File::Spec::Functions qw(
	catdir catfile catpath tmpdir splitpath rel2abs curdir
);
use     Archive::Tar     1.42 qw();
use     File::HomeDir         qw();
use     File::Remove          qw();
use     File::pushd           qw();
use     File::ShareDir        qw();
use     File::Copy::Recursive qw();
use     File::PathList        qw();
use     HTTP::Status          qw();
use     IO::File              qw();
use     IO::String            qw();
use     IO::Handle            qw();
use     IPC::Run3             qw();
use     LWP::UserAgent        qw();
use     LWP::Online           qw();
use     Module::CoreList 2.18 qw();
use     PAR::Dist             qw();
use     Probe::Perl           qw();
use     SelectSaver           qw();
use     Template              qw();
use     URI                   qw();
use     Win32                 qw();
require File::List::Object;
require Perl::Dist::WiX::Exceptions;
require Perl::Dist::WiX::DirectoryTree2;
require Perl::Dist::WiX::FeatureTree2;
require Perl::Dist::WiX::Fragment::CreateFolder;
require Perl::Dist::WiX::Fragment::Files;
require Perl::Dist::WiX::Fragment::Environment;
require Perl::Dist::WiX::Fragment::StartMenu;
require Perl::Dist::WiX::IconArray;
require Perl::Dist::WiX::MergeModule;
require WiX3::XML::GeneratesGUID::Object;
require WiX3::Traceable;

our $VERSION = '1.100_001';
$VERSION =~ s/_//;

use Moose::Tiny qw(
  bin_perl
  bin_make
  bin_pexports
  bin_dlltool
  msi_feature_tree
  feature_tree_obj
  icons
);

has 'toolchain' => (
	is => 'bare', # Perl::Dist::WiX::Util::Toolchain object
	reader => '_get_toolchain',
	writer => '_set_toolchain',	
	init_arg => undef,
);

has 'checkpoint_before' => (
	is => 'ro', # Integer
	default => 0,
);

has 'checkpoint_dir' => (
	is => 'ro', # String
	default => 0,
);

has 'checkpoint_after' => (
	is => 'ro', # Array of Integers
	default => sub { return [0] },
);

has 'checkpoint_stop' => (
	is => 'ro', # Integer
	default => 0,
);

# These attributes are either created in BUILDARGS, or are created later, 
# and cannot be passed to new().

has 'build_start_time' => (
	is => 'ro', # Integer
	default => time,
	init_arg => undef, # Cannot set this parameter in new().
);

has '_directories' => (
	is => 'ro', # Perl::Dist::WiX::DirectoryTree2
	writer => '_set_directories',
	default => undef,
	init_arg => undef,
);

has 'distributions_installed' => (
	is => 'ro', # Array of strings
	default => sub { return [] },
	init_arg => undef,
);

has 'env_path' => (
	is => 'ro', # Array of strings
	default => sub { return [] },
	init_arg => undef,
);

has 'output_file' => (
	is => 'ro', # Array of strings
	default => sub { return [] },
	init_arg => undef,
);


has '_filters' => (
	is => 'ro', # Array of directories
	lazy => 1,
	builder => '_build_filters',
	init_arg => undef,
);

sub _build_filters {
	my $self = shift;
	
	# Initialize filters.
#<<<
	return [   $self->temp_dir() . q{\\},
	  catdir ( $self->image_dir(), qw{ perl man         } ) . q{\\},
	  catdir ( $self->image_dir(), qw{ perl html        } ) . q{\\},
	  catdir ( $self->image_dir(), qw{ c    man         } ) . q{\\},
	  catdir ( $self->image_dir(), qw{ c    doc         } ) . q{\\},
	  catdir ( $self->image_dir(), qw{ c    info        } ) . q{\\},
	  catdir ( $self->image_dir(), qw{ c    contrib     } ) . q{\\},
	  catdir ( $self->image_dir(), qw{ c    html        } ) . q{\\},
	  catdir ( $self->image_dir(), qw{ c    examples    } ) . q{\\},
	  catdir ( $self->image_dir(), qw{ c    manifest    } ) . q{\\},
	  catdir ( $self->image_dir(), qw{ cpan sources     } ) . q{\\},
	  catdir ( $self->image_dir(), qw{ cpan build       } ) . q{\\},
	  catdir ( $self->image_dir(), qw{ c    bin         startup mac   } ) . q{\\},
	  catdir ( $self->image_dir(), qw{ c    bin         startup msdos } ) . q{\\},
	  catdir ( $self->image_dir(), qw{ c    bin         startup os2   } ) . q{\\},
	  catdir ( $self->image_dir(), qw{ c    bin         startup qssl  } ) . q{\\},
	  catdir ( $self->image_dir(), qw{ c    bin         startup tos   } ) . q{\\},
	  catdir ( $self->image_dir(), qw{ c    libexec     gcc     mingw32 3.4.5 install-tools}) . q{\\},
	  catfile( $self->image_dir(), qw{ c    COPYING     } ),
	  catfile( $self->image_dir(), qw{ c    COPYING.LIB } ),
	  catfile( $self->image_dir(), qw{ c    bin         gccbug  } ),
	  catfile( $self->image_dir(), qw{ c    bin         mingw32-gcc-3.4.5  } ),
	  ];
#>>>
}

# TODO: Document get_fragment_object and fragment_exists.

has '_fragments' => (
	traits   => ['Hash'],
	is       => 'bare',
	isa      => 'HashRef', # Hashref[Perl::Dist::WiX::Fragment]
	default  => sub { return {} },
	init_arg => undef,
    handles   => {
		get_fragment_object => 'get',
		fragment_exists     => 'defined',
		_add_fragment       => 'set',
		_clear_fragments    => 'clear',
		_fragment_keys      => 'keys',
	},
);

has '_merge_modules' => (
	traits   => ['Hash'],
	is       => 'bare',
	isa      => 'HashRef', # Hashref[Perl::Dist::WiX::MergeModule]
	default  => sub { return {} },
	init_arg => undef,
    handles   => {
		get_merge_module_object => 'get',
		merge_module_exists     => 'defined',
		_add_merge_module       => 'set',
		_clear_merge_modules    => 'clear',
		_merge_module_keys      => 'keys',
	},
);

has '_output_file' => (
	traits  => ['Array'],
	is => 'ro', # Array of strings
	default => sub { return [] },
	init_arg => undef,
    handles   => {
		add_output_file => 'push',
		add_output_files => 'push',
		get_output_files => 'elements',
	},
);

has '_perl_version_corelist' => (
	is => 'ro', # Hash
	lazy => 1,
	builder => '_build_perl_version_corelist',
	init_arg => undef,
);

sub _build_perl_version_corelist {
	my $self = shift;

	# Find the core list
	my $corelist_version = $self->perl_version_literal() + 0;
	my $hash = $Module::CoreList::version{$corelist_version};
	unless ( _HASH( $hash ) ) {
		PDWiX->throw( 'Failed to resolve Module::CoreList hash for '
			  . $self->perl_version_human() );
	}	
	return $hash;
}

has 'pdw_class' => (
	is => 'ro', # String
	required => 1,	# Default is provided in BUILDARGS.	
);

has 'pdw_version' => (
	is => 'ro', # String
	default => $Perl::Dist::WiX::VERSION,
	init_arg => undef, # Cannot set this parameter in new().
);

has '_guidgen' => (
	is => 'ro', # WiX3::XML::GeneratesGUID::Object
	required => 1,	# Default is provided in BUILDARGS.
);

has '_trace_object' => (
	is => 'ro', # WiX3::Traceable
	required => 1,
	handles => [ 'trace_line' ],
);

has _user_agent_directory => (
	is => 'ro', # Directory that is created in builder, so must exist.
	lazy => 1,
	builder => '_build_user_agent_directory',
	init_arg => undef,
);

sub _build_user_agent_directory {
	my $self = shift;

# Create a legal path out of the object's class name under {Application Data}/Perl.
	my $path = ref $self;
	$path =~ s{::}{-}gmsx;             # Changes all :: to -.
	my $dir = File::Spec->catdir( File::HomeDir->my_data(), 'Perl', $path, );

	# Make the directory or die vividly.
	unless ( -d $dir ) {
		unless ( File::Path::mkpath( $dir, { verbose => 0 } ) ) {
			PDWiX->throw("Failed to create $dir");
		}
	}
	unless ( -w $dir ) {
		PDWiX->throw(
			"No write permissions for LWP::UserAgent cache '$dir'");
	}
	return $dir;
} ## end sub user_agent_directory



	#  Don't need to put distributions_installed in here.

#>>>



#####################################################################
# Constructor

=pod

=head2 new

The B<new> method creates a Perl::Dist::WiX object that describes a 
distribution of perl.

Each object is used to create a single distribution by calling C<run()>, 
and then should be discarded.

Although there are about 30 potential constructor arguments that can be
provided, most of them are automatically resolved and exist for overloading
puposes only, or they revert to sensible defaults and generally never need
to be modified.

This routine may take a few minutes to run.

An example of the most likely attributes that will be specified is in the 
SYNOPSIS.

Attributes that are required to be set are marked as I<(required)> 
below.  They may often be set by subclasses.

All attributes below can also be called as accessors on the object created.


=head3 app_id I<(required)>

The C<app_id> parameter provides the base identifier of the distribution 
that is used in constructing filenames by default.  This must be a legal 
Perl identifier (no spaces, for example) and is required.

=cut

has 'app_id' => (
	is => 'ro', # String that passes _IDENTIFIER
	required => 1,
);



=head3 app_name I<(required)>

The C<app_name> parameter provides the name of the distribution. This is 
required.

=cut

has 'app_name' => (
	is => 'ro', # String
	required => 1,
);



=head3 app_publisher I<(required)>

The C<app_publisher> parameter provides the publisher of the distribution. 

=cut

has 'app_publisher' => (
	is => 'ro', # String
	required => 1,
);



=head3 app_publisher_url I<(required)>

The C<app_publisher_url> parameter provides the URL of the publisher of 
the distribution.

=cut

has 'app_publisher_url' => (
	is => 'ro', # URL
	required => 1,
);



=head3 app_ver_name

The C<app_ver_name> parameter provides the name and version of the distribution. 

This is not required, and is assembled from C<app_name> and 
C<perl_version_human> if not given.

=cut

has 'app_ver_name' => (
	is => 'ro', # String
	lazy => 1,
	builder => '_build_app_ver_name' ,
);

sub _build_app_ver_name { 
	my $self = shift; 
	return $self->app_name() . q{ } . $self->perl_version_human(); 
}



=head3 beta_number

The optional integer C<beta_number> parameter is used to set the beta number
portion of the distribution's version number (if this is a beta distribution), 
and is used in constructing filenames.

It defaults to 0 if not set, which will construct distributions without a beta
number.

=cut

has 'beta_number' => (
	is => 'ro', # Integer
	default => 0,
);



=head3 binary_root

The C<binary_root> accessor is the URL (as a string, not including the 
filename) where the distribution will find its libraries to download.

Defaults to 'http://strawberryperl.com/package' unless C<offline> is set, 
in which case it defaults to the empty string.

=cut

has 'binary_root' => (
	is => 'ro', # URL
	lazy => 1,
	builder => '_build_binary_root',
);

sub _build_binary_root {
	my $self = shift;

	if ( $self->offline() ) {
		return q{};
	} else {
		return 'http://strawberryperl.com/package';
	}
}


=head3 bits

The optional C<bits> parameter specifies whether the perl being built is 
for 32-bit (i386) or 64-bit (referred to as Intel64 / amd-x64) Windows

32-bit (i386) is the default.

=cut

has 'bits' => (
	is => 'ro', # Integer 32/64
	default => 32,
);



=head3 build_dir

The directory where the source files for the distribution will be 
extracted and built from.

Defaults to C<temp_dir> . '\build', and must exist if given.

=cut

has 'build_dir' => (
	is => 'ro', # Directory that must exist.
	lazy => 1,
	builder => '_build_build_dir' ,
);

sub _build_build_dir {
	my $self = shift;
	
	my $dir = catdir( $self->temp_dir(), 'build' );
	$self->_remake_path( $dir );
	return $dir;
}



=head3 build_number I<(required)>

The required integer C<build_number> parameter is used to set the build number
portion of the distribution's version number, and is used in constructing filenames.

=cut

has 'build_number' => (
	is => 'ro', # Integer
	required => 1,
);



=head3 cpan

The C<cpan> param provides a path to a CPAN or minicpan mirror that
the installer can use to fetch any needed files during the build
process.

The param should be a L<URI> object to the root of the CPAN repository,
including trailing slash.

If you are online and no C<cpan> param is provided, the value will
default to the L<http://cpan.strawberryperl.com> repository as a
convenience.

=cut

has 'cpan' => (
	is => 'ro', # URI object
	lazy => 1,
	builder => '_build_cpan',
);

sub _build_cpan {
	my $self = shift;
	
	# If we are online and don't have a cpan repository,
	# use cpan.strawberryperl.com as a default.
	if ( $self->offline() ) {
		PDWiX::Parameter->throw(
			parameter => 'cpan: Required if offline => 1',
			where     => '->new'
		);
	} else {
		return URI->new('http://cpan.strawberryperl.com/');
	}
}



=head3 debug_stderr

The optional C<debug_stderr> parameter is used to set the location of the file
that STDERR is redirected to when the perl tarball and perl modules are built.

The default location is in C<debug.err> in the C<output_dir>.

=cut

has 'debug_stderr' => (
	is => 'ro', # String
	lazy => 1,
	default => sub { 
		my $self = shift; 
		return catfile( $self->output_dir(), 'debug.err' ); 
	},
);



=head3 debug_stdout

The optional C<debug_stdout> parameter is used to set the location of the file
that STDOUT is redirected to when the perl tarball and perl modules are built.

The default location is in C<debug.out> in the C<output_dir>.

=cut

has 'debug_stdout' => (
	is => 'ro', # String
	lazy => 1,
	default => sub { 
		my $self = shift; 
		return catfile( $self->output_dir(), 'debug.out' ); 
	},
);



=head3 default_group_name

The name for the Start menu group that the distribution's installer 
installs its shortcuts to.  Defaults to C<app_name> if none is provided.

=cut

has 'default_group_name' => (
	is => 'ro', # String
	lazy => 1,
	default => sub {
		my $self = shift;
		return $self->app_name() 
	},
);



=head3 download_dir 

The optional C<download_dir> parameter sets the location of the directory 
that packages of various types will be downloaded and cached to.

Defaults to C<temp_dir> . '\download', and must exist if given.

=cut

has 'download_dir' => (
	is => 'ro', # Directory that must exist.
	lazy => 1,
	builder => '_build_download_dir' ,
);

sub _build_download_dir {
	my $self = shift;
	
	my $dir = catdir( $self->temp_dir(), 'download' );
	$self->_make_path($dir);
	return $dir;
}



=head3 exe

The optional boolean C<exe> param is unused at the moment.

=cut

has 'exe' => (
	is => 'ro', # Boolean
	writer => '_set_exe',
	default => 0,
);



=head3 force

The C<force> parameter determines if perl and perl modules are 
tested upon installation.  If this parameter is true, then no 
testing is done.

=cut

has 'force' => (
	is => 'ro', # Boolean
	default => 0,
);



=head3 forceperl

The C<force> parameter determines if perl and perl modules are 
tested upon installation.  If this parameter is true, then testing 
is done only upon installed modules, not upon perl itself.

=cut

has 'forceperl' => (
	is => 'ro', # Boolean
	default => 0,
);



=head3 fragment_dir

The subdirectory of C<temp_dir> where the .wxs fragment files for the 
different portions of the distribution will be created. 

Defaults to C<temp_dir> . '\fragments', and needs to exist if given.

=cut

has 'fragment_dir' => (
	is => 'ro', # Directory that must exist.
	lazy => 1,
	builder => '_build_fragment_dir' ,
);

sub _build_fragment_dir {
	my $self = shift;
	
	my $dir = catdir( $self->temp_dir(), 'fragments' );
	$self->_remake_path( $dir );
	return $dir;
}

=head3 gcc_version

The optional C<gcc_version> parameter specifies whether perl is being built 
using gcc 3.4.5 from the mingw32 project (by specifying a value of '3'), or 
using gcc 4.4.3 from the mingw64 project (by specifying a value of '4'). 

'3' (gcc 3.4.5) is the default, and is incompatible with bits => 64.
'4' is compatible with both 32 and 64-bit.

=cut

has 'gcc_version' => (
	is => 'ro', # Integer 3-4
	default => 3,
);



=head3 git_checkout

The C<git_checkout> parameter is not used unless you specify that 
C<perl_version> is 'git'. In that event, this parameter should contain 
a string pointing to the location of a checkout from 
L<http://perl5.git.perl.org/>.

The default is 'C:\perl-git\'.

=cut

has 'git_checkout' => (
	is => 'ro',
	isa => 'Str',
	default => qq{C:\\perl-git\\},
);



=head3 git_location

The C<git_location> parameter is not used unless you specify that 
C<perl_version> is 'git'. In that event, this parameter should contain 
a string pointing to the location of the git.exe binary, as because
a perl.exe file is in the same directory, it gets removed from the PATH 
during the execution of programs from Perl::Dist::WiX.
 
The default is 'C:\Program Files\Git\bin\git.exe'>.

People on x64 systems should set this to 
C<'C:\Program Files (x86)\Git\bin\git.exe'> unless MSysGit is installed 
in a different location (or a 64-bit version becomes available).

This will be converted to a short name before execution, so this must 
NOT be on a partition that does not have them, unless the location does
not have spaces.

=cut

has 'git_location' => (
	is => 'ro',
	isa => 'Str',
	default => 'C:\Program Files\Git\bin\git.exe',
);



=head3 image_dir I<(required)>

Perl::Dist::WiX distributions can only be installed to fixed paths
as of yet.

To facilitate a correctly working CPAN setup, the files that will
ultimately end up in the installer must also be assembled under the
same path on the author's machine.

The C<image_dir> method specifies the location of the Perl install,
both on the author's and end-user's host.

Please note that this directory will be automatically deleted if it
already exists at object creation time. Trying to build a Perl
distribution on the SAME distribution can thus have devastating
results, and an attempt is made to prevent this from happening.

=cut

has 'image_dir' => (
	is => 'ro', # Directory, but must exist (will be created in BUILDARGS).
	required => 1,
);



=head3 license_dir

The subdirectory of image_dir where the licenses for the different 
portions of the distribution will be copied to. 

Defaults to C<image_dir> . '\licenses', and needs to exist if given.

=cut

has 'license_dir' => (
	is => 'ro', # Directory that must exist.
	lazy => 1,
	builder => '_build_license_dir' ,
);

sub _build_license_dir {
	my $self = shift;
	
	my $dir = catdir( $self->image_dir(), 'licenses' );
	$self->_remake_path($dir);
	return $dir;
}

=head3 modules_dir

The optional C<modules_dir> parameter sets the location of the directory 
that perl modules will be downloaded and cached to.

Defaults to C<download_dir> . '\modules', and must exist if given.

=cut

has 'modules_dir' => (
	is => 'ro', # Directory that must exist.
	lazy => 1,
	builder => '_build_modules_dir' ,
);

sub _build_modules_dir {
	my $self = shift;
	
	my $dir = catdir( $self->download_dir(), 'modules' );
	$self->_make_path($dir);
	return $dir;
}




=head3 msi

The optional boolean C<msi> param is used to indicate that a Windows
Installer distribution package (otherwise known as an msi file) should 
be created.

=cut

has 'msi' => (
	is => 'ro', # Boolean
	writer => '_set_msi',
	default => sub { 
		my $self = shift; 
		return $self->portable() ? 0 : 1;
	},
);



=head3 msi_banner_side

The optional C<msi_banner_side> parameter specifies the location of 
a 493x312 .bmp file that is used in the introductory dialog in the MSI 
file.

WiX will use its default if no file is supplied here.

=cut

has 'msi_banner_side' => (
	is => 'ro', # File that needs to exist
);



=head3 msi_banner_top

The optional C<msi_banner_top> parameter specifies the location of a 
493x58 .bmp file that is  used on the top of most of the dialogs in 
the MSI file.

WiX will use its default if no file is supplied here.

=cut

has 'msi_banner_top' => (
	is => 'ro', # File that needs to exist
);



=head3 msi_debug

The optional boolean C<msi_debug> parameter is used to indicate that
a debugging MSI (one that creates a log in $ENV{TEMP} upon execution
in Windows Installer 4.0 or above) will be created if C<msi> is also 
true.

=cut

has 'msi_debug' => (
	is => 'ro', # Boolean
	default => 0,
);



=head3 msi_help_url

The optional C<msi_help_url> parameter specifies the URL that 
Add/Remove Programs directs you to for support when you click 
the "Click here for support information." text.

=cut

has 'msi_help_url' => (
	is => 'ro', # URL that is not required
);



=head3 msi_license_file

The optional C<msi_license_file> parameter specifies the location of an 
.rtf or .txt file to be displayed at the point where the MSI asks you 
to accept a license.

Perl::Dist::WiX provides a default one if none is supplied here.

=cut

has 'msi_license_file' => (
	is => 'ro', # File that needs to exist
	lazy => 1,
	default => sub { 
		my $self = shift;
		return catfile( $self->wix_dist_dir(), 'License.rtf' );
	},
);



=head3 msi_product_icon

The optional C<msi_product_icon> parameter specifies the icon that is 
used in Add/Remove Programs for this MSI file.

=cut

has 'msi_product_icon' => (
	is => 'ro', # File that needs to exist
);



=head3 msi_readme_file

The optional C<msi_readme_file> parameter specifies a .txt or .rtf file 
or a URL (TODO: check) that is linked in Add/Remove Programs in the 
"Click here for support information." text.

=cut

has 'msi_readme_file' => (
	is => 'ro', # File that needs to exist
);



=head3 offline

The B<Perl::Dist::WiX> module has limited ability to build offline, if all
packages have already been downloaded and cached.

The connectedness of the Perl::Dist object is checked automatically
be default using L<LWP::Online|LWP::Online>. It can be overidden 
by providing the C<offline> parameter to new().

The C<offline> accessor returns true if no connection to "the internet"
is available and the object will run in offline mode, or false
otherwise.

=cut

has 'offline' => (
	is => 'ro',
	default => sub { return LWP::Online::offline() },
);



=head3 output_base_filename

The optional C<output_base_filename> parameter specifies the filename 
(without extensions) that is used for the installer(s) being generated.

The default is based on C<app_id>, C<perl_version>, C<bits>, and the 
current date.

=cut

has 'output_base_filename' => (
	is => 'ro', # String
	lazy => 1,
	builder => '_build_output_base_filename',
);
	
# Default the output filename to the id plus the current date
sub _build_output_base_filename {
	my $self = shift;
	
	my $bits = (64 == $self->bits) ? q{64bit-} : q{};
	
	return
	    $self->app_id() . q{-}
	  . $self->perl_version_human() . q{-}
	  . $bits
	  . $self->output_date_string();
}



=head3 output_dir

This is the location where the compiled installers and other files 
neccessary to the build are written.

Defaults to C<temp_dir> . '\output', and must exist when given.

=cut

has 'output_dir' => (
	is => 'ro', # Directory that must exist.
	lazy => 1,
	builder => '_build_output_dir' ,
);

sub _build_output_dir {
	my $self = shift;
	
	my $dir = catdir( $self->temp_dir(), 'output' );
	$self->_make_path( $dir );
	return $dir;
}



=head3 perl_config_cf_email

The optional C<perl_config_cf_email> parameter specifies the e-mail
of the person building the perl distribution defined by this object.

It is compiled into the perl binary as the C<cf_email> option accessible
through C<perl -V:cf_email>.

The username (the part before the at sign) of this parameter also sets the
C<cf_by> option.

If not defined, this is set to anonymous@unknown.builder.invalid.

=cut

has 'perl_config_cf_email' => (
	is => 'ro', # E-mail address
	default => 'anonymous@unknown.builder.invalid',
);



=head3 perl_config_cf_by

The optional C<perl_config_cf_email> parameter specifies the username part
of the e-mail address of the person building the perl distribution defined 
by this object.

It is compiled into the perl binary as the C<cf_by> option accessible
through C<perl -V:cf_by>.

If not defined, this is set to the username part of C<perl_config_cf_email>.

=cut

has 'perl_config_cf_by' => (
	is => 'ro', # String
	lazy => 1,
	builder => '_build_perl_config_cf_by' ,
);

sub _build_perl_config_cf_by {
	my $self = shift;
	return $self->perl_config_cf_email() =~ m/\A(.*)@.*\z/msx 
};



=head3 perl_version

The C<perl_version> parameter specifies what version of perl is downloaded 
and built.  Legal values for this parameter are 'git', '589', '5100', and 
'5101' (for a version from perl5.git.perl.org, 5.8.9, 5.10.0, and 5.10.1, 
respectively.)

This parameter defaults to '5101' if not specified.

=cut

has 'perl_version' => (
	is => 'ro',
	isa => 'Str',
	default => '5101',
);



=head3 portable

The optional C<portable> parameter is used to determine whether a portable
'Perl-on-a-stick' distribution - one that is intended for distribution on
a portable storage device - is built with this object.

If set to a true value, C<zip> must also be set to a true value, and C<msi> 
will be set to a false value.

This defaults to a false value. 

=cut

has 'portable' => (
	is => 'ro', # Boolean
	default => 0,
);



=head3 sitename

The optional C<sitename> parameter is used to generate the GUID's necessary
during the process of building the distribution.

This defaults to the host part of C<app_publisher_url>.

=cut

has 'sitename' => (
	is => 'ro', # Hostname
	required => 1,	# Default is provided in BUILDARGS.
);



=head3 tasklist

The optional C<tasklist> parameter specifies the list of routines that the 
object can do.  This is usually set by a subclass, and if one is not set,
Perl::Dist::WiX provides a default one.

=cut

has 'tasklist' => (
	is => 'ro', # Array of strings that the object can do.
	builder => '_build_tasklist',	# Default is provided in BUILDARGS.
);

sub _build_tasklist {
	return [

		# Final initialization
		'final_initialization',

		# Install the core C toolchain
		'install_c_toolchain',

		# Install the Perl binary
		'install_perl',

		# Install the Perl toolchain
		'install_perl_toolchain',

		# Install additional Perl modules
		'install_cpan_upgrades',

		# Apply optional portability support
		'install_portable',

		# Remove waste and temporary files
		'remove_waste',

		# Regenerate file fragments
		'regenerate_fragments',

		# Write out the merge module
		'write_merge_module',

		# Install the Win32 extras
		'install_win32_extras',

		# Create the distribution list
		'create_distribution_list',

		# Regenerate file fragments again.
		'regenerate_fragments',

		# Write out the distributions
		'write',
	];
}



=head3 temp_dir

B<Perl::Dist::WiX> needs a series of temporary directories while
it is running the build, including places to cache downloaded files,
somewhere to expand tarballs to build things, and somewhere to put
debugging output and the final installer zip and msi files.

The C<temp_dir> param specifies the root path for where these
temporary directories should be created.

For convenience it is best to make these short paths with simple
names, near the root.

This parameter defaults to a subdirectory of $ENV{TEMP} if not specified.

=cut

has 'temp_dir' => (
	is => 'ro',
	default => sub { return catdir( tmpdir(), 'perldist' ) },
);



=head3 trace

The C<trace> parameter sets the level of tracing that is output.

Setting this parameter to 0 prints out only MAJOR stuff and errors.

Setting this parameter to 2 or above will print out the level as the 
first thing on the line, and when an error occurs and an exception 
object is printed, a stack trace will be printed as well.

Setting this parameter to 3 or above will print out the filename and 
line number after the trace level on those lines that require a trace 
level of 3 or above to print.

Setting this parameter to 5 or above will print out the filename and 
line number on every line.

Default is 1 if not set.

=cut

has 'trace' => (
	is => 'ro', # Integer
	default => 1,
);



=head3 user_agent

TODO

=cut

has 'user_agent' => (
	is => 'ro', # LWP::UserAgent instance
	lazy => 1,
	builder => '_build_user_agent',
);

sub _build_user_agent {
	my $self = shift;
	my $ua;
	
	if ( $self->user_agent_cache() ) {
	  SCOPE: {

			# Temporarily set $ENV{HOME} to the File::HomeDir
			# version while loading the module.
			local $ENV{HOME} ||= File::HomeDir->my_home;
			require LWP::UserAgent::WithCache;
		}
		$ua = LWP::UserAgent::WithCache->new( {
				agent              => ref($self) . q{/} . ( $VERSION || '0.00' ),
				namespace          => 'perl-dist',
				cache_root         => $self->_user_agent_directory(),
				cache_depth        => 0,
				default_expires_in => 86_400 * 30,
				show_progress      => 1,
			} );
	} else {
		$ua = LWP::UserAgent->new(
			agent         => ref($self) . q{/} . ( $VERSION || '0.00' ),
			timeout       => 30,
			show_progress => 1,
		);
	}

	return $ua;
} ## end sub user_agent



=head3 user_agent_cache

TODO

=cut

has 'user_agent_cache' => (
	is => 'ro', # Boolean
	default => 1,
);

=head3 zip

The optional boolean C<zip> param is used to indicate that a zip
distribution package should be created.

=cut

has 'zip' => (
	is => 'ro', # Boolean
	lazy => 1,
	default => sub { 
		my $self = shift; 
		return $self->portable() ? 1 : 0;
	},
);




# Note that new() is actually defined by Moose.  BUILDARGS() is called before
# new() and processes the arguments for it.

sub BUILDARGS {
	my $class  = shift;
	my %params;

	if ( @_ == 1 && 'HASH' eq ref $_[0] ) {
		%params = %{ $_[0] };
	} elsif ( 0 == @_ % 2 ) {
		%params = (@_);
	} else {
		PDWiX->throw(
			'Parameters incorrect (not a hashref or hash) for Perl::Dist::WiX->new()');
	}

	eval { 
		$params{_trace_object} ||= WiX3::Traceable->new( tracelevel => $params{trace} );
		1;
	} || eval {
		WiX3::Trace::Object->_clear_instance();
		WiX3::Traceable->_clear_instance();
		$params{_trace_object} ||= WiX3::Traceable->new( tracelevel => $params{trace} );
	} || die "Could not create trace object";

	# Announce that we're starting.
	{
		my $time = scalar localtime;
		$params{_trace_object}->trace_line( 0, "Starting build at $time.\n" );
	}

	# Get the parameters required for the GUID generator set up.
	unless ( _STRING( $params{app_publisher_url} ) ) {
		PDWiX::Parameter->throw(
			parameter => 'app_publisher_url',
			where     => '::Installer->new'
		);
	}

	unless ( _STRING( $params{sitename} ) ) {
		$params{sitename} = URI->new( $params{app_publisher_url} )->host;
	}

	$params{_guidgen} ||=
	  WiX3::XML::GeneratesGUID::Object->new(
		_sitename => $params{sitename} );


	if ( $params{temp_dir} =~ m{[.]}ms ) {
		PDWiX::Parameter->throw(
			parameter => 'temp_dir: Cannot be '
			  . 'a directory that has a . in the name.',
			where => '->new'
		);
	}

	if ( defined $params{build_dir} && $params{build_dir} =~ m{[.]}ms ) {
		PDWiX::Parameter->throw(
			parameter => 'build_dir: Cannot be '
			  . 'a directory that has a . in the name.',
			where => '->new'
		);
	}
	
	if ( defined $params{image_dir} ) {
		my $perl_location = lc Probe::Perl->find_perl_interpreter();
		$params{_trace_object}
		  ->trace_line( 3, "Currently executing perl: $perl_location\n" );
		my $our_perl_location =
		  lc catfile( $params{image_dir}, qw(perl bin perl.exe) );
		$params{_trace_object}->trace_line( 3,
			"Our perl to create:       $our_perl_location\n" );

		PDWiX::Parameter->throw(
			parameter => ' image_dir : attempting to commit suicide ',
			where     => '->new'
		) if ( $our_perl_location eq $perl_location );

		PDWiX::Parameter->throw(
			parameter =>
			  ' image_dir : cannot contain two consecutive slashes ',
			where => '->new'
		) if ( $params{image_dir} =~ m{\\\\}ms );

		PDWiX::Parameter->throw(
			parameter => 'image_dir: Spaces are not allowed',
			where     => '->new'
		) if ( $params{image_dir} =~ /\s/ms );

		# We don't want to delete a previous one yet.
		$class->_make_path( $params{image_dir} );
	} else {
		PDWiX::Parameter->throw(
			parameter => 'image_dir: is not defined',
			where => '->new'
		)
	}
	
	if ( $params{app_name} =~ m{[\\/:*"<>|]}msx ) {
		PDWiX::Parameter->throw(
			parameter => 'app_name: Contains characters invalid '
			  . 'for Windows file/directory names',
			where => '->new'
		);
	}

	# TODO: Use this as the type checker for output_dir, image_dir, and fragment_dir.
	# unless ( -w $self->output_dir() && -d $self->output_dir() ) {
		# $self->trace_line( 0,
			# 'Directory does not exist or is not writable: ' . $self->output_dir . "\n" );
		# PDWiX::Parameter->throw(
			# parameter => 'output_dir: Directory does not exist or is not writable',
			# where     => '::Installer->new'
		# );
	# }

	$params{pdw_class} = $class;
	
	return \%params;
} ## end sub new

# Handle moving the CPAN source files back.
sub DESTROY {
	my $self = shift;

	if ( defined $self->{'_cpan_moved'} && $self->{'_cpan_moved'} ) {
		my $x = eval {
			File::Remove::remove( \1, $self->{'_cpan_sources_from'} );
			File::Copy::Recursive::move(
				$self->{'_cpan_sources_to'},
				$self->{'_cpan_sources_from'} );
		};
	}

	return;
} ## end sub DESTROY

sub final_initialization {
	my $self = shift;

	# If we have a file:// url for the CPAN, move the
	# sources directory out of the way.

	if ( $self->cpan()->as_string() =~ m{\Afile://}mxsi ) {
		require CPAN;
		CPAN::HandleConfig->load unless $CPAN::Config_loaded++;

		my $cpan_path_from = $CPAN::Config->{'keep_source_where'};
		my $cpan_path_to =
		  rel2abs( catdir( $cpan_path_from, q{..}, 'old_sources' ) );

		$self->trace_line( 0, "Moving CPAN sources files:\n" );
		$self->trace_line( 2, <<"EOF");
  From: $cpan_path_from
  To:   $cpan_path_to
EOF

		File::Copy::Recursive::move( $cpan_path_from, $cpan_path_to );

		$self->{'_cpan_sources_from'} = $cpan_path_from;
		$self->{'_cpan_sources_to'}   = $cpan_path_to;
		$self->{'_cpan_moved'}        = 1;
	} else {
		$self->{'_cpan_moved'} = 0;
	}

	unless ( $self->cpan()->as_string() =~ m{\/\z}ms ) {
		PDWiX::Parameter->throw(
			parameter => 'cpan: Missing trailing slash',
			where     => '->new'
		);
	}

	unless ( $self->can( 'install_perl_' . $self->perl_version() ) ) {
		my $class = ref $self;
		PDWiX->throw(
			"$class does not support Perl " . $self->perl_version() );
	}

	if ( $self->build_dir() =~ /\s/ms ) {
		PDWiX::Parameter->throw(
			parameter => 'build_dir: Spaces are not allowed',
			where     => '->final_initialization'
		);
	}

	# Handle portable special cases
	if ( $self->portable() ) {
		$self->_set_exe(0);
		$self->_set_msi(0);
		if ( not $self->zip() ) {
			PDWiX->throw( 'Cannot be portable and not build a .zip' );
		}
	}

	## no critic(ProtectPrivateSubs)
	# Set element collections
	$self->trace_line( 2, "Creating in-memory directory tree...\n" );
	Perl::Dist::WiX::DirectoryTree2->_clear_instance();
	$self->_set_directories(
		Perl::Dist::WiX::DirectoryTree2->new(
			app_dir  => $self->image_dir(),
			app_name => $self->app_name(),
		)->initialize_tree( $self->perl_version )
	);

	$self->_add_fragment('Environment', 
	  Perl::Dist::WiX::Fragment::Environment->new());

	$self->_add_fragment('CreateCpan',
	  Perl::Dist::WiX::Fragment::CreateFolder->new(
		directory_id => 'Cpan',
		id           => 'CPANFolder',
	  ));
	$self->_add_fragment('CreateCpanplus', 
	  Perl::Dist::WiX::Fragment::CreateFolder->new(
		directory_id => 'Cpanplus',
		id           => 'CPANPLUSFolder',
	  )) if ( '589' ne $self->perl_version() );

	# Clear the par cache, just to be safe.
	# Sometimes, if not cleared, PAR fails tests.
	my $par_temp = catdir( $ENV{TEMP}, 'par-' . Win32::LoginName() );
	if ( -d $par_temp ) {
		$self->trace_line( 1, 'Removing ' . $par_temp . "\n" );
		File::Remove::remove( \1, $par_temp );
	}

	my @directories_to_make = ( 
		catdir( $self->image_dir, 'cpan' ),
	);

	push @directories_to_make, catdir( $self->image_dir, 'cpanplus' ) if ( '589' ne $self->perl_version() );

	# Initialize the build
	for my $d (@directories_to_make)
	{
		next if -d $d;
		File::Path::mkpath($d);
	}

	# Empty directories that need emptied.
	$self->trace_line( 1,
		"Wait a second while we empty the image, output, and fragment directories...\n" );
	$self->_remake_path( $self->image_dir() );
	$self->_remake_path( $self->output_dir() );
	$self->_remake_path( $self->fragment_dir() );
	
	$self->add_env( 'TERM',        'dumb' );
	$self->add_env( 'FTP_PASSIVE', '1' );

	return 1;
} ## end sub final_initialization

=head2 Accessors

	$id = $dist->bin_candle; 

Accessors will return a specified portion of the distribution state.

If it can also be set as a parameter to C<new>, it is marked as I<(also C<new> parameter)> below.

=head3 fragment_dir

The location where this object will write the information for WiX 
to process to create the MSI. A default is provided if this is not 
specified.

=head3 directories

Returns the L<Perl::Dist::WiX::DirectoryTree|Perl::Dist::WiX::DirectoryTree> 
object associated with this distribution.  Created by L</new>

=head3 fragments

Returns a hashref containing the objects subclassed from 
L<Perl::Dist::WiX::Base::Fragment|Perl::Dist::WiX::Base::Fragment> 
associated with this distribution. Created as the distribution's 
L</run> routine progresses.

=head3 msi_feature_tree

Returns the parameter of the same name passed in 
from L</new>. Unused as of yet.

=head3 msi_product_icon_id

Specifies the Id for the icon that is used in Add/Remove Programs for 
this MSI file.

=head3 feature_tree_obj

Returns the L<Perl::Dist::WiX::FeatureTree|Perl::Dist::WiX::FeatureTree> 
object associated with this distribution.

=cut


=head3 checkpoint_dir

I<(also C<new> parameter)>

The directory where Perl::Dist::WiX will store its checkpoints. 

Defaults to C<temp_dir> . '\checkpoint', and must exist if given.

=head3 bin_perl, bin_make, bin_pexports, bin_dlltool

The location of perl.exe, dmake.exe, pexports.exe, and dlltool.exe.

These only are available (not undef) once the appropriate packages 
are installed.

=head3 env_path

An arrayref storing the different directories under C<image_dir> that 
need to be added to the PATH.

=head3 dist_dir

Provides a shortcut to the location of the shared files directory.

Returns a directory as a string or throws an exception on error.

=cut

sub dist_dir {
	my $self = shift;

	return $self->wix_dist_dir();
}

=head3 wix_dist_dir

Provides a shortcut to the location of the shared files directory for 
C<Perl::Dist::WiX>.

Returns a directory as a string or throws an exception on error.

=cut

has 'wix_dist_dir' => (
	is => 'ro', # String
	builder => '_build_wix_dist_dir',
	init_arg => undef,
);

sub _build_wix_dist_dir {
	my $dir;

	unless ( eval { $dir = File::ShareDir::dist_dir('Perl-Dist-WiX'); 1; } )
	{
		PDWiX::Caught->throw(
			message =>
			  'Could not find distribution directory for Perl::Dist::WiX',
			info => ( defined $EVAL_ERROR ) ? $EVAL_ERROR : 'Unknown error',
		);
	}

	return $dir;
} ## end sub wix_dist_dir

#####################################################################
# Accessors and Documentation for accessors.

=head3 git_describe

The C<git_describe> method returns the output of C<git describe> on the
directory pointed to by C<git_checkout>.

=cut

has 'git_describe' => (
	is => 'ro', # String
	lazy => 1,
	builder => '_build_git_describe',
	init_arg => undef,
);

sub _build_git_describe {
	my $self = shift;
	my $checkout = $self->git_checkout();
	my $location = $self->git_location();
	if (not -f $location) {
		PDWiX->throw("Could not find git at $location");
	}
	$location = Win32::GetShortPathName($location);
	if (not defined $location) {
		PDWiX->throw("Could not convert the location of git.exe to a path with short names");
	}
	$self->trace_line(2, "Finding current commit using $location describe\n");
	my $describe = qx{cmd.exe /d /e:on /c "pushd $checkout && $location describe && popd"};
	
	if ($CHILD_ERROR){
		PDWiX->throw("'git describe' returned an error: $CHILD_ERROR");
	}
	
	$describe =~ s/v5[.]/5./;
	$describe =~ s/\n//;	
	
	return $describe;
}



=head3 perl_version_literal

The C<perl_version_literal> method returns the literal numeric Perl
version for the distribution.

For Perl 5.8.8 this will be '5.008008', Perl 5.8.9 will be '5.008009',
and for Perl 5.10.0 this will be '5.010000'.

=cut

has 'perl_version_literal' => (
	is => 'ro', # String
	lazy => 1,
	builder => '_build_perl_version_literal',
	init_arg => undef,
);

sub _build_perl_version_literal {
	my $self = shift;
	
	my $x = {
		'589'  => '5.008009',
		'5100' => '5.010000',
		'5101' => '5.010001',
		'git'  => '5.011001',
	  }->{ $self->perl_version() }
	  || 0;
	  
	unless ( $x ) {
		PDWiX::Parameter->throw(
			parameter => 'perl_version_literal: Failed to resolve',
			where     => '->(building of accessor)'
		);
	}

	return $x;
}

=head3 perl_version_human

The C<perl_version_human> method returns the "marketing" form
of the Perl version.

This will be either 'git', '5.8.9', '5.10.0', or '5.10.1'.

=cut

has 'perl_version_human' => (
	is => 'ro', # String
	lazy => 1,
	builder => '_build_perl_version_human',
	writer => '_set_perl_version_human',
	init_arg => undef,
);

sub _build_perl_version_human {
	my $self = shift;
	
	my $x = {
		'589'  => '5.8.9',
		'5100' => '5.10.0',
		'5101' => '5.10.1',
		'git'  => 'git',
	  }->{ $self->perl_version() }
	  || 0;
	  
	unless ( $x ) {
		PDWiX::Parameter->throw(
			parameter => 'perl_version_human: Failed to resolve',
			where     => '->(building of accessor)'
		);
	}

	return $x;
}

=head3 distribution_version_human

The C<distribution_version_human> method returns the "marketing" form
of the distribution version.

=cut

sub distribution_version_human {
	my $self = shift;
	
	my $version = $self->perl_version_human();
	
	if ('git' eq $version) {
		$version = $self->git_describe();
	}

	return
	    $version . q{.} . $self->build_number()
	  . ( $self->portable() ? ' Portable' : q{} )
	  . ( $self->beta_number() ? ' Beta ' . $self->beta_number() : q{} );
}

=head3 output_date_string

Returns a stringified date in YYYYMMDD format for the use of other 
routines.

=cut

# Convenience method
sub output_date_string {
	my @t = localtime;
	return sprintf '%04d%02d%02d', $t[5] + 1900, $t[4] + 1, $t[3];
}

=head3 msi_ui_type

Returns the UI type that the MSI needs to use.

=cut

# For template
sub msi_ui_type {
	my $self = shift;
	return ( defined $self->msi_feature_tree() ) ? 'FeatureTree' : 'Minimal';
}

=head3 msi_platform_string

Returns the Platform attribute to the MSI's Package tag.

See L<http://wix.sourceforge.net/manual-wix3/wix_xsd_package.htm>

=cut

# For template
sub msi_platform_string {
	my $self = shift;
	return ( 64 == $self->bits() ) ? 'x64' : 'x86';
}

=head3 msi_product_icon_id

Returns the product icon to use in the main template.

=cut

sub msi_product_icon_id {
	my $self = shift;

	# Get the icon ID if we can.
	if ( defined $self->msi_product_icon() ) {
		return 'I_' . $self->icons()->search_icon( $self->msi_product_icon );
	} else {
		return undef;
	}
} ## end sub msi_product_icon_id

=head3 msi_product_id

Returns the Id for the MSI's <Product> tag.

See L<http://wix.sourceforge.net/manual-wix3/wix_xsd_product.htm>

=cut

# For template
sub msi_product_id {
	my $self = shift;

	my $generator = WiX3::XML::GeneratesGUID::Object->instance();

	my $product_name =
	    $self->app_name()
	  . ( $self->portable() ? ' Portable ' : q{ } )
	  . $self->app_publisher_url()
	  . q{ ver. }
	  . $self->msi_perl_version();

	#... then use it to create a GUID out of the ID.
	my $guid = $generator->generate_guid($product_name);

	return $guid;
} ## end sub msi_product_id

=head3 msm_product_id

Returns the Id for the <Product> tag for the MSI's merge module.

See L<http://wix.sourceforge.net/manual-wix3/wix_xsd_product.htm>

=cut

# For template
sub msm_product_id {
	my $self = shift;

	my $generator = WiX3::XML::GeneratesGUID::Object->instance();

	my $product_name =
	    $self->app_name()
	  . ( $self->portable() ? ' Portable ' : q{ } )
	  . $self->app_publisher_url()
	  . q{ ver. }
	  . $self->msi_perl_version()
	  . q{ merge module.};

	#... then use it to create a GUID out of the ID.
	my $guid = $generator->generate_guid($product_name);
	$guid =~ s/-/_/g;

	return $guid;
} ## end sub msi_product_id


=head3 msi_upgrade_code

Returns the Id for the MSI's <Upgrade> tag.

See L<http://wix.sourceforge.net/manual-wix3/wix_xsd_upgrade.htm>

=cut

# For template
sub msi_upgrade_code {
	my $self = shift;

	my $generator = WiX3::XML::GeneratesGUID::Object->instance();

	my $upgrade_ver =
	    $self->app_name()
	  . ( $self->portable() ? ' Portable' : q{} ) . q{ }
	  . $self->app_publisher_url();

	#... then use it to create a GUID out of the ID.
	my $guid = $generator->generate_guid($upgrade_ver);

	return $guid;
} ## end sub msi_upgrade_code

=head3 msm_package_id

Returns the Id for the MSI's <Package> tag.

See L<http://wix.sourceforge.net/manual-wix3/wix_xsd_package.htm>

=cut

# For template
sub msm_package_id {
	my $self = shift;

	my $generator = WiX3::XML::GeneratesGUID::Object->instance();

	my $upgrade_ver =
	    $self->app_name()
	  . ( $self->portable() ? ' Portable' : q{} ) . q{ }
	  . $self->app_publisher_url()
	  . q{ merge module.};

	#... then use it to create a GUID out of the ID.
	my $guid = $generator->generate_guid($upgrade_ver);
	
	return $guid;
} ## end sub msi_upgrade_code


=head3 msi_perl_version

Returns the Version attribute for the MSI's <Product> tag.

See L<http://wix.sourceforge.net/manual-wix3/wix_xsd_product.htm>

=cut

# For template.
# MSI versions are 3 part, not 4, with the maximum version being 255.255.65535
sub msi_perl_version {
	my $self = shift;

	# Get perl version arrayref.
	my $ver = {
		'589'  => [ 5, 8,  9 ],
		'5100' => [ 5, 10, 0 ],
		'5101' => [ 5, 10, 1 ],
		'git'  => [ 5, 0,  0 ],
	  }->{ $self->perl_version }
	  || [ 0, 0, 0 ];

	# Merge build number with last part of perl version.
	$ver->[2] = ( $ver->[2] << 8 ) + $self->build_number();

	return join q{.}, @{$ver};

} ## end sub msi_perl_version

=head3 perl_config_myuname

Returns the value to be used for perl -V:myuname, which is in this pattern:

	Win32 app_id 5.10.0.1.beta_1 #1 Mon Jun 15 23:11:00 2009 i386
	
(the .beta_X is ommitted if the beta_number accessor is not set.)

=cut

# For template.
# MSI versions are 3 part, not 4, with the maximum version being 255.255.65535
sub perl_config_myuname {
	my $self = shift;

	my $version = $self->perl_version_human() . q{.} . $self->build_number();
	
	if ($version =~ m/git/) {
		$version = $self->git_describe() . q{.} . $self->build_number();
	}
	
	if ( $self->beta_number() > 0 ) {
		$version .= '.beta_' . $self->beta_number();
	}

	my $bits = (64 == $self->bits()) ? 'x86_64' : 'i386';
	
	return join q{ }, 'Win32', $self->app_id(), $version, '#1',
	  $self->build_start_time(), 'i386';

} ## end sub perl_config_myuname

=head3 get_component_array

Returns the array of <Component Id>'s required.

See L<http://wix.sourceforge.net/manual-wix3/wix_xsd_component.htm>, 
L<http://wix.sourceforge.net/manual-wix3/wix_xsd_componentref.htm>

=back

=cut

sub get_component_array {
	my $self = shift;

	print "Running get_component_array...\n";
	my @answer;
	foreach my $key ( $self->_fragment_keys ) {
		push @answer, $self->get_fragment_object($key)->get_componentref_array();
	}

	return @answer;
}

#####################################################################
# Top Level Process Methods

sub prepare { return 1 }

=pod

=head2 run

The C<run> method is the main method for the class.

It does a complete build of a product, spitting out an installer.

Returns true, or throws an exception on error.

This method may take an hour or more to run.

=cut

sub run {
	my $self  = shift;
	my $start = time;

	unless ( $self->msi or $self->zip ) {
		$self->trace_line('No msi or zip target, nothing to do');
		return 1;
	}

	# Don't buffer
	STDOUT->autoflush(1);
	STDERR->autoflush(1);

	my @task_list   = @{ $self->tasklist() };
	my $task_number = 1;
	my $task;
	my $answer = 1;

	while ( $answer and ( $task = shift @task_list ) ) {
		$answer = $self->checkpoint_task( $task => $task_number );
		$task_number++;
	}

	# Finished
	$self->trace_line( 0,
		    'Distribution generation completed in '
		  . ( time - $start )
		  . " seconds\n" );
	foreach my $file ( $self->get_output_files ) {
		$self->trace_line( 0, "Created distribution $file\n" );
	}

	return 1;
} ## end sub run

#####################################################################
# Perl::Dist::WiX Main Methods

=head2 Routines used by C<run>

=head3 install_c_toolchain

The C<install_c_toolchain> method is used by C<run> to install various
binary packages to provide a working C development environment.

By default, the C toolchain consists of dmake, gcc (C/C++), binutils,
pexports, the mingw runtime environment, and the win32api C package.

Although dmake is the "standard" make for Perl::Dist distributions,
it will also install the mingw version of GNU make for use with 
those modules that require it.

=cut

# Install the required toolchain elements.
# We use separate methods for each tool to make
# it easier for individual distributions to customize
# the versions of tools they incorporate.
sub install_c_toolchain {
	my $self = shift;

	# The primary make
	$self->install_dmake;

	# Core compiler and support libraries.
	$self->install_gcc_toolchain;

	# C Utilities
	$self->install_mingw_make;
	$self->install_pexports;

	# Set up the environment variables for the binaries
	$self->add_env_path( 'c', 'bin' );

	return 1;
} ## end sub install_c_toolchain

# Portability support must be added after modules
sub install_portable {
	my $self = shift;

	return 1 unless $self->portable;

	# Install the regular parts of Portability
	$self->install_modules( qw(
		  Sub::Uplevel
		  ) ) unless $self->isa('Perl::Dist::Strawberry');
	$self->install_modules( qw(
		  Test::Exception
	) );
	$self->install_modules( qw(
		  Test::Tester
		  Test::NoWarnings
		  LWP::Online
		  ) ) unless $self->isa('Perl::Dist::Strawberry');
	$self->install_modules( qw(
		  Class::Inspector
		  CPAN::Mini
		  Portable
		  ) ) unless $self->isa('Perl::Dist::Bootstrap');

	# Create the portability object
	$self->trace_line( 1, "Creating Portable::Dist\n" );
	require Portable::Dist;
	$self->{portable_dist} =
	  Portable::Dist->new( perl_root => catdir( $self->image_dir, 'perl' ),
	  );
	$self->trace_line( 1, "Running Portable::Dist\n" );
	$self->{portable_dist}->run;
	$self->trace_line( 1, "Completed Portable::Dist\n" );

	# Install the file that turns on Portability last
	$self->install_file(
		share      => 'Perl-Dist-WiX portable\portable.perl',
		install_to => 'portable.perl',
	);

	# Install files to help use Strawberry Portable.
	$self->install_file(
		share      => 'Perl-Dist-WiX portable\README.portable.txt',
		install_to => 'README.portable.txt',
	);
	$self->install_file(
		share      => 'Perl-Dist-WiX portable\portableshell.bat',
		install_to => 'portableshell.bat',
	);

	return 1;
} ## end sub install_portable

# Install links and launchers and so on
sub install_win32_extras {
	my $self = shift;

	File::Path::mkpath( catdir( $self->image_dir, 'win32' ) );

	# TODO: Delete next two statements.
#	my $perldir = $self->{directories}->search_dir(
#		path_to_find => catdir( $self->image_dir, 'perl' ),
#		exact        => 1,
#		descend      => 1,
#	);
#	$perldir->add_directory(
#		name => 'bin',
#		id   => 'PerlBin',
#		path => catdir( $self->image_dir, qw( perl bin ) ),
#	);

	$self->install_launcher(
		name => 'CPAN Client',
		bin  => 'cpan',
	);
	$self->install_website(
		name      => 'CPAN Search',
		url       => 'http://search.cpan.org/',
		icon_file => catfile( $self->wix_dist_dir(), 'cpan.ico' ) );

	if ( $self->perl_version_human eq '5.8.9' ) {
		$self->install_website(
			name      => 'Perl 5.8.9 Documentation',
			url       => 'http://perldoc.perl.org/5.8.9/',
			icon_file => catfile( $self->wix_dist_dir(), 'perldoc.ico' ) );
	}
	if ( $self->perl_version_human eq '5.10.0' ) {
		$self->install_website(
			name      => 'Perl 5.10.0 Documentation',
			url       => 'http://perldoc.perl.org/5.10.0/',
			icon_file => catfile( $self->wix_dist_dir(), 'perldoc.ico' ) );
	}
	if ( $self->perl_version_human eq '5.10.1' ) {
		$self->install_website(
			name      => 'Perl 5.10.1 Documentation',
			url       => 'http://perldoc.perl.org/',
			icon_file => catfile( $self->wix_dist_dir(), 'perldoc.ico' ) );
	}
	$self->install_website(
		name      => 'Win32 Perl Wiki',
		url       => 'http://win32.perl.org/',
		icon_file => catfile( $self->wix_dist_dir(), 'win32.ico' ) );

	return $self;
} ## end sub install_win32_extras

# Delete various stuff we won't be needing
sub remove_waste {
	my $self = shift;

	$self->trace_line( 1, "Removing waste\n" );
	$self->trace_line( 2,
		"  Removing doc, man, info and html documentation\n" );
	$self->_remove_dir(qw{ perl man       });
	$self->_remove_dir(qw{ perl html      });
	$self->_remove_dir(qw{ c    man       });
	$self->_remove_dir(qw{ c    doc       });
	$self->_remove_dir(qw{ c    info      });
	$self->_remove_dir(qw{ c    contrib   });
	$self->_remove_dir(qw{ c    html      });

	$self->trace_line( 2, "  Removing C examples, manifests\n" );
	$self->_remove_dir(qw{ c    examples  });
	$self->_remove_dir(qw{ c    manifest  });

	$self->trace_line( 2, "  Removing extra dmake/gcc files\n" );
	$self->_remove_dir(qw{ c    bin         startup mac   });
	$self->_remove_dir(qw{ c    bin         startup msdos });
	$self->_remove_dir(qw{ c    bin         startup os2   });
	$self->_remove_dir(qw{ c    bin         startup qssl  });
	$self->_remove_dir(qw{ c    bin         startup tos   });
	$self->_remove_dir(
		qw{ c    libexec     gcc     mingw32 3.4.5 install-tools});

	$self->trace_line( 2, "  Removing redundant files\n" );
	$self->_remove_file(qw{ c COPYING     });
	$self->_remove_file(qw{ c COPYING.LIB });
	$self->_remove_file(qw{ c bin gccbug  });
	$self->_remove_file(qw{ c bin mingw32-gcc-3.4.5 });

	$self->trace_line( 2,
		"  Removing CPAN build directories and download caches\n" );
	$self->_remove_dir(qw{ cpan sources  });
	$self->_remove_dir(qw{ cpan build    });
	$self->_remove_file(qw{ cpan cpandb.sql });
	$self->_remove_file(qw{ cpan FTPstats.yml });
	$self->_remove_file(qw{ cpan cpan_sqlite_log.* });

	# Readding the cpan directory.
	$self->_remake_path( catdir( $self->build_dir, 'cpan' ) );

	return 1;
} ## end sub remove_waste

sub _remove_dir {
	my $self = shift;
	my $dir  = $self->_dir(@_);
	File::Remove::remove( \1, $dir ) if -e $dir;
	return 1;
}

sub _remove_file {
	my $self = shift;
	my $file = $self->_file(@_);
	File::Remove::remove( \1, $file ) if -e $file;
	return 1;
}

#####################################################################
# Package Generation

sub regenerate_fragments {
	my $self = shift;

	return 1 unless $self->msi;

	# Add the perllocal.pod here, because apparently it's disappearing.
	if ($self->fragment_exists('perl')) {	
		$self->add_to_fragment( 'perl',
			[ catfile( $self->image_dir(), qw( perl lib perllocal.pod ) ) ] );
	}
	
	my @fragment_names_regenerate;
	my @fragment_names = $self->_fragment_keys();

	while ( 0 != scalar @fragment_names ) {
		foreach my $name (@fragment_names) {
			my $fragment = $self->get_fragment_object($name);
			if ( defined $fragment ) {
				push @fragment_names_regenerate, $fragment->regenerate();
			} else {
				$self->trace_line( 0,
"Couldn't regenerate fragment $name because fragment object did not exist.\n"
				);
			}
		}

		$#fragment_names = -1;         # clears the array.
		@fragment_names             = uniq @fragment_names_regenerate;
		$#fragment_names_regenerate = -1;
	} ## end while ( 0 != scalar @fragment_names)

	return 1;
} ## end sub regenerate_fragments

#####################################################################
# Package Generation

sub write { ## no critic 'ProhibitBuiltinHomonyms'
	my $self = shift;

# TODO: Temporarily comment out.
#	if ( $self->zip ) {
#		$self->add_output_files($self->write_zip);
#	}
	if ( $self->msi ) {
		$self->add_output_files($self->write_msi);
	}
	return 1;
} ## end sub write

sub write_merge_module {
	my $self = shift;

	if ( $self->msi ) {

		$self->add_output_files($self->write_msm);
		
		# Save off the contents of the image directory so that
		# they can be used later without having to rebuild the
		# whole distribution.
		my $file_out =
		  catfile( $self->output_dir, $self->output_base_filename . '.msm-contents.zip' );

		rename $self->write_zip(), $file_out;
		
		$self->add_output_file($file_out);

		$self->_clear_fragments();
		
		my $file =
		  catfile( $self->output_dir(), 'fragments.zip' );
		$self->trace_line( 1, "Generating zip at $file\n" );

		# Create the archive
		my $zip = Archive::Zip->new();

		# Add the fragments directory to the root
		$zip->addTree( $self->fragment_dir(), q{} );

		my @members = $zip->members();

		# Set max compression for all members, deleting .AAA files.
		foreach my $member (@members) {
			next if $member->isDirectory();
			$member->desiredCompressionLevel(9);
			if ( $member->fileName =~ m{[.] wixout\z}smx ) {
				$zip->removeMember($member);
			}
		}

		# Write out the file name
		$zip->writeToFileNamed($file);

		# Remake the fragments directory.
		$self->_remake_path($self->fragment_dir());
		
		# Reset the directory tree.
		$self->_set_directories(undef);
		Perl::Dist::WiX::DirectoryTree2->_clear_instance();
		$self->_set_directories(
			Perl::Dist::WiX::DirectoryTree2->new(
				app_dir  => $self->image_dir(),
				app_name => $self->app_name(),
			)->initialize_short_tree( $self->perl_version )
		);
	}

	# Start adding the fragments that are only for the .msi.
	$self->_add_fragment('StartMenuIcons',
	  Perl::Dist::WiX::Fragment::StartMenu->new(
		directory_id => 'D_App_Menu', ));
	$self->_add_fragment('Win32Extras', 
	  Perl::Dist::WiX::Fragment::Files->new(
		id    => 'Win32Extras',
		files => File::List::Object->new(),
	  ));
	$self->{icons} = $self->get_fragment_object('StartMenuIcons')->get_icons();
	if ( defined $self->msi_product_icon() ) {
		$self->icons()->add_icon( $self->msi_product_icon() );
	}
	
	return 1;
} ## end sub write_msm

=pod

=head2 write_zip

The C<write_zip> method is used to generate a standalone .zip file
containing the entire distribution, for situations in which a full
installer database is not wanted (such as for "Portable Perl"
type installations).

The .zip file is written to the output directory, and the location
of the file is printed to STDOUT.

Returns true or throws an exception or error.

=cut

sub write_zip {
	my $self = shift;
	my $file =
	  catfile( $self->output_dir, $self->output_base_filename . '.zip' );
	$self->trace_line( 1, "Generating zip at $file\n" );

	# Create the archive
	my $zip = Archive::Zip->new();

	# Add the image directory to the root
	$zip->addTree( $self->image_dir(), q{} );

	my @members = $zip->members();

	# Set max compression for all members, deleting .AAA files.
	foreach my $member (@members) {
		next if $member->isDirectory();
		$member->desiredCompressionLevel(9);
		if ( $member->fileName =~ m{[.] AAA\z}smx ) {
			$zip->removeMember($member);
		}
	}

	# Write out the file name
	$zip->writeToFileNamed($file);

	return $file;
} ## end sub write_zip

sub add_icon {
	my $self   = shift;
	my %params = @_;
	my ( $vol, $dir, $file, $dir_id );

	# Get the Id for directory object that stores the filename passed in.
	( $vol, $dir, $file ) = splitpath( $params{filename} );
	$self->trace_line(0, "Directory being searched for: $vol $dir\n"); 
	$dir_id = $self->_directories()->search_dir(
		path_to_find => catdir( $vol, $dir ),
		exact        => 1,
		descend      => 1,
	)->get_id();

	# Get a legal id.
	my $id = $params{name};
	$id =~ s{\s}{_}msxg;               # Convert whitespace to underlines.

	# Add the start menu icon.
	$self->get_fragment_object('StartMenuIcons')->add_shortcut(
		name        => $params{name},
		description => $params{name},
		target      => "[D_$dir_id]$file",
		id          => $id,
		working_dir => $dir_id,
		icon_id     => $params{icon_id},
	);

	return $self;
} ## end sub add_icon

sub add_env_path {
	my $self = shift;
	my @path = @_;
	my $dir  = catdir( $self->image_dir, @path );
	unless ( -d $dir ) {
		PDWiX->throw("PATH directory $dir does not exist");
	}
	push @{ $self->{env_path} }, [@path];
	return 1;
}

sub get_env_path {
	my $self = shift;
	return join q{;},
	  map { catdir( $self->image_dir, @{$_} ) } @{ $self->env_path };
}

#####################################################################
# Main Methods

=head2 compile_wxs($filename, $wixobj)

Compiles a .wxs file (specified by $filename) into a .wixobj file 
(specified by $wixobj.)  Both parameters are required.

	$self = $self->compile_wxs("Perl.wxs", "Perl.wixobj");

=cut

sub compile_wxs {
	my ( $self, $filename, $wixobj ) = @_;
	my @files = @_;

	# Check parameters.
	unless ( _STRING($filename) ) {
		PDWiX::Parameter->throw(
			parameter => 'filename',
			where     => '::Installer->compile_wxs'
		);
	}
	unless ( _STRING($wixobj) ) {
		PDWiX::Parameter->throw(
			parameter => 'wixobj',
			where     => '::Installer->compile_wxs'
		);
	}
	unless ( -r $filename ) {
		PDWiX->throw("$filename does not exist or is not readable");
	}

	# Compile the .wxs file
	my $cmd = [
		wix_bin_candle(),
		'-out', $wixobj,
		$filename,

	];
	my $out;
	my $rv = IPC::Run3::run3( $cmd, \undef, \$out, \undef );

	if ( ( not -f $wixobj ) and ( $out =~ /error|warning/msx ) ) {
		$self->trace_line( 0, $out );
		PDWiX->throw( "Failed to find $wixobj (probably "
			  . "compilation error in $filename)" );
	}


	return $rv;
} ## end sub compile_wxs

=pod

=head2 write_msi

  $self->write_msi;

The C<write_msi> method is used to generate the compiled installer
executable. It creates the entire installation file tree, and then
executes WiX to create the final executable.

This method should only be called after all installation phases have
been completed and all of the files for the distribution are in place.

The executable file is written to the output directory, and the location
of the file is printed to STDOUT.

Returns true or throws an exception or error.

=cut

sub write_msi {
	my $self = shift;

	my $dir = $self->fragment_dir;
	my ( $fragment, $fragment_name, $fragment_string );
	my ( $filename_in, $filename_out );
	my $fh;
	my @files;

	$self->trace_line( 1, "Generating msi\n" );

  FRAGMENT:

	# Write out .wxs files for all the fragments and compile them.
	foreach my $key ( $self->_fragment_keys() ) {
		$fragment        = $self->get_fragment_object($key);
		$fragment_string = $fragment->as_string;
		next
		  if ( ( not defined $fragment_string )
			or ( $fragment_string eq q{} ) );
		$fragment_name = $fragment->get_id;
		$filename_in   = catfile( $dir, $fragment_name . q{.wxs} );
		$filename_out  = catfile( $dir, $fragment_name . q{.wixout} );
		$fh            = IO::File->new( $filename_in, 'w' );

		if ( not defined $fh ) {
			PDWiX->throw(
"Could not open file $filename_in for writing [$OS_ERROR] [$EXTENDED_OS_ERROR]"
			);
		}
		$fh->print($fragment_string);
		$fh->close;
		$self->trace_line( 2, "Compiling $filename_in\n" );
		$self->compile_wxs( $filename_in, $filename_out )
		  or PDWiX->throw("WiX could not compile $filename_in");

		unless ( -f $filename_out ) {
			PDWiX->throw( "Failed to find $filename_out (probably "
				  . "compilation error in $filename_in)" );
		}

		push @files, $filename_out;
	} ## end foreach my $key ( keys %{ $self...})

	# Generate feature tree.
	$self->{feature_tree_obj} =
	  Perl::Dist::WiX::FeatureTree2->new( parent => $self, );

	# Write out the .wxs file
	my $content = $self->as_string('Main.wxs.tt');
	$content =~ s{\r\n}{\n}msg;        # CRLF -> LF
	$filename_in =
	  catfile( $self->fragment_dir, $self->app_name . q{.wxs} );

	if ( -f $filename_in ) {

		# Had a collision. Yell and scream.
		PDWiX->throw(
			"Could not write out $filename_in: File already exists.");
	}
	$filename_out =
	  catfile( $self->fragment_dir, $self->app_name . q{.wixobj} );
	$fh = IO::File->new( $filename_in, 'w' );

	if ( not defined $fh ) {
		PDWiX->throw(
"Could not open file $filename_in for writing [$OS_ERROR] [$EXTENDED_OS_ERROR]"
		);
	}
	$fh->print($content);
	$fh->close;

	# Compile the main .wxs
	$self->trace_line( 2, "Compiling $filename_in\n" );
	$self->compile_wxs( $filename_in, $filename_out )
	  or PDWiX->throw("WiX could not compile $filename_in");
	unless ( -f $filename_out ) {
		PDWiX->throw( "Failed to find $filename_out (probably "
			  . "compilation error in $filename_in)" );
	}

	# Start linking the msi.

	# Get the parameters for the msi linking.
	my $output_msi =
	  catfile( $self->output_dir, $self->output_base_filename . '.msi', );
	my $input_wixouts = catfile( $self->fragment_dir, '*.wixout' );
	my $input_wixobj =
	  catfile( $self->fragment_dir, $self->app_name . '.wixobj' );

	# Link the .wixobj files
	$self->trace_line( 1, "Linking $output_msi\n" );
	my $out;
	my $cmd = [
		wix_bin_light(),
		'-sice:ICE38',                 # Gets rid of ICE38 warning.
		'-sice:ICE43',                 # Gets rid of ICE43 warning.
		'-sice:ICE47',                 # Gets rid of ICE47 warning.
		                               # (Too many components in one
		                               # feature for Win9X)
#		'-sice:ICE48',                 # Gets rid of ICE48 warning.
		                               # (Hard-coded installation location)

#		'-v',                          # Verbose for the moment.
		'-out', $output_msi,
		'-ext', wix_lib_wixui(),
		$input_wixobj,
		$input_wixouts,
	];
	my $rv = IPC::Run3::run3( $cmd, \undef, \$out, \undef );

	$self->trace_line( 1, $out );

	# Did everything get done correctly?
	if ( ( not -f $output_msi ) and ( $out =~ /error|warning/msx ) ) {
		$self->trace_line( 0, $out );
		PDWiX->throw(
			"Failed to find $output_msi (probably compilation error)");
	}

	return $output_msi;
} ## end sub write_msi

=pod

=head2 write_msm

  $self->write_msm;

The C<write_msm> method is used to generate the compiled merge module
used in the installer. It creates the entire installation file tree, and then
executes WiX to create the merge module.

This method should only be called after all installation phases that 
install perl modules have been completed and all of the files for the 
merge module are in place.

The merge module file is written to the output directory, and the location
of the file is printed to STDOUT.

Returns true or throws an exception or error.

=cut

sub write_msm {
	my $self = shift;

	my $dir = $self->fragment_dir;
	my ( $fragment, $fragment_name, $fragment_string );
	my ( $filename_in, $filename_out );
	my $fh;
	my @files;

	$self->trace_line( 1, "Generating msm\n" );

	# Add the path in.
	foreach my $value ( map { '[INSTALLDIR]' . catdir( @{$_} ) }
		@{ $self->env_path } )
	{
		$self->add_env( 'PATH', $value, 1 );
	}

  FRAGMENT:

	# Write out .wxs files for all the fragments and compile them.
	foreach my $key ( $self->_fragment_keys() ) {
		$fragment        = $self->get_fragment_object($key);
		$fragment_string = $fragment->as_string;
		next
		  if ( ( not defined $fragment_string )
			or ( $fragment_string eq q{} ) );
		$fragment_name = $fragment->get_id;
		$filename_in   = catfile( $dir, $fragment_name . q{.wxs} );
		$filename_out  = catfile( $dir, $fragment_name . q{.wixout} );
		$fh            = IO::File->new( $filename_in, 'w' );

		if ( not defined $fh ) {
			PDWiX->throw(
"Could not open file $filename_in for writing [$OS_ERROR] [$EXTENDED_OS_ERROR]"
			);
		}
		$fh->print($fragment_string);
		$fh->close;
		$self->trace_line( 2, "Compiling $filename_in\n" );
		$self->compile_wxs( $filename_in, $filename_out )
		  or PDWiX->throw("WiX could not compile $filename_in");

		unless ( -f $filename_out ) {
			PDWiX->throw( "Failed to find $filename_out (probably "
				  . "compilation error in $filename_in)" );
		}

		push @files, $filename_out;
	} ## end foreach my $key ( keys %{ $self...})

	# Generate feature tree.
	$self->{feature_tree_obj} =
	  Perl::Dist::WiX::FeatureTree2->new( parent => $self, );

	# Write out the .wxs file
	my $content = $self->as_string('Merge-Module.wxs.tt');
	$content =~ s{\r\n}{\n}msg;        # CRLF -> LF
	$filename_in =
	  catfile( $self->fragment_dir, $self->app_name . q{.wxs} );

	if ( -f $filename_in ) {

		# Had a collision. Yell and scream.
		PDWiX->throw(
			"Could not write out $filename_in: File already exists.");
	}
	$filename_out =
	  catfile( $self->fragment_dir, $self->app_name . q{.wixobj} );
	$fh = IO::File->new( $filename_in, 'w' );

	if ( not defined $fh ) {
		PDWiX->throw(
"Could not open file $filename_in for writing [$OS_ERROR] [$EXTENDED_OS_ERROR]"
		);
	}
	$fh->print($content);
	$fh->close;

	# Compile the main .wxs
	$self->trace_line( 2, "Compiling $filename_in\n" );
	$self->compile_wxs( $filename_in, $filename_out )
	  or PDWiX->throw("WiX could not compile $filename_in");
	unless ( -f $filename_out ) {
		PDWiX->throw( "Failed to find $filename_out (probably "
			  . "compilation error in $filename_in)" );
	}

# Start linking the merge module.

	# Get the parameters for the msi linking.
	my $output_msm =
	  catfile( $self->output_dir, $self->output_base_filename . '.msm', );
	my $input_wixouts = catfile( $self->fragment_dir, '*.wixout' );
	my $input_wixobj =
	  catfile( $self->fragment_dir, $self->app_name . '.wixobj' );

	# Link the .wixobj files
	$self->trace_line( 1, "Linking $output_msm\n" );
	my $out;
	my $cmd = [
		wix_bin_light(),
#		'-sice:ICE38',                 # Gets rid of ICE38 warning.
#		'-sice:ICE43',                 # Gets rid of ICE43 warning.
#		'-sice:ICE47',                 # Gets rid of ICE47 warning.
		                               # (Too many components in one
		                               # feature for Win9X)
#		'-sice:ICE48',                 # Gets rid of ICE48 warning.
		                               # (Hard-coded installation location)

#		'-v',                          # Verbose for the moment.
		'-out', $output_msm,
		'-ext', wix_lib_wixui(),
		$input_wixobj,
		$input_wixouts,
	];
	my $rv = IPC::Run3::run3( $cmd, \undef, \$out, \undef );

	$self->trace_line( 1, $out );

	# Did everything get done correctly?
	if ( ( not -f $output_msm ) and ( $out =~ /error|warning/msx ) ) {
		$self->trace_line( 0, $out );
		PDWiX->throw(
			"Failed to find $output_msm (probably compilation error)");
	}

	return $output_msm;
} ## end sub write_msm

=pod

=head2 add_env($name, $value I<[, $append]>)

Adds the contents of $value to the environment variable $name 
(or appends to it, if $append is true) upon installation (by 
adding it to the Reg_Environment fragment.)

$name and $value are required. 

=cut

sub add_env {
	my ( $self, $name, $value, $append ) = @_;

	unless ( defined $append ) {
		$append = 0;
	}

	unless ( _STRING($name) ) {
		PDWiX::Parameter->throw(
			parameter => 'name',
			where     => '::Installer->add_env'
		);
	}

	unless ( _STRING($value) ) {
		PDWiX::Parameter->throw(
			parameter => 'value',
			where     => '::Installer->add_env'
		);
	}

	my $env_fragment = $self->get_fragment_object('Environment');
	my $num = $env_fragment->get_entries_count();

	$env_fragment->add_entry(
		id     => "Env_$num",
		name   => $name,
		value  => $value,
		action => 'set',
		part   => $append ? 'last' : 'all',
	);

	return $self;
} ## end sub add_env

=head2 add_file({source => $filename, fragment => $fragment_name})

Adds the file C<$filename> to the fragment named by C<$fragment_name>.

Both parameters are required, and the file and fragment must both exist. 

=cut

sub add_file {
	my ( $self, %params ) = @_;

	unless ( _STRING( $params{source} ) ) {
		PDWiX::Parameter->throw(
			parameter => 'source',
			where     => '::Installer->add_file'
		);
	}

	unless ( -f $params{source} ) {
		PDWiX->throw("File $params{source} does not exist");
	}

	unless ( _IDENTIFIER( $params{fragment} ) ) {
		PDWiX::Parameter->throw(
			parameter => 'fragment',
			where     => '::Installer->add_file'
		);
	}

	unless ( $self->fragment_exists( $params{fragment} ) ) {
		PDWiX->throw("Fragment $params{fragment} does not exist");
	}

	$self->get_fragment_object( $params{fragment} )->add_file( $params{source} );

	return $self;
} ## end sub add_file

=head2 insert_fragment($id, $files_ref)

Adds the list of files C<$files_ref> to the fragment named by C<$id>.

The fragment is created by this routine, so this can only be done once.

This B<MUST> be done for each set of files to be installed in an MSI.

=cut

sub insert_fragment {
	my ( $self, $id, $files_obj, $overwritable ) = @_;

	# Check parameters.
	unless ( _IDENTIFIER($id) ) {
		PDWiX::Parameter->throw(
			parameter => 'id',
			where     => '::Installer->insert_fragment'
		);
	}
	unless ( _INSTANCE( $files_obj, 'File::List::Object' ) ) {
		PDWiX::Parameter->throw(
			parameter => 'files_obj',
			where     => '::Installer->insert_fragment'
		);
	}

	defined $overwritable or $overwritable = 0;

	$self->trace_line( 2, "Adding fragment $id...\n" );

	my $frag;
  FRAGMENT:
	foreach my $frag_key ( $self->_fragment_keys() ) {
		$frag = $self->get_fragment_object($frag_key);
		next FRAGMENT
		  if not $frag->isa('Perl::Dist::WiX::Fragment::Files');
		$frag->check_duplicates($files_obj);
	}

	my $fragment = Perl::Dist::WiX::Fragment::Files->new(
		id            => $id,
		files         => $files_obj,
		can_overwrite => $overwritable,
	);

	$self->_add_fragment($id, $fragment);

	return $fragment;
} ## end sub insert_fragment

=head2 add_to_fragment($id, $files_ref)

Adds the list of files C<$files_ref> to the fragment named by C<$id>.

The fragment must already exist.

=cut

sub add_to_fragment {
	my ( $self, $id, $files_ref ) = @_;

	# Check parameters.
	unless ( _IDENTIFIER($id) ) {
		PDWiX::Parameter->throw(
			parameter => 'id',
			where     => '->add_to_fragment'
		);
	}
	unless ( _ARRAY($files_ref) ) {
		PDWiX::Parameter->throw(
			parameter => 'files_ref',
			where     => '->add_to_fragment'
		);
	}

	if ( not $self->fragment_exists($id) ) {
		PDWiX->throw("Fragment $id does not exist");
	}

	my @files = @{$files_ref};

	my $files_obj = File::List::Object->new()->add_files(@files);

	my $frag;
	foreach my $frag_key ( $self->_fragment_keys() ) {
		$frag = $self->get_fragment_object($frag_key);
		$frag->check_duplicates($files_obj);
	}

	my $fragment = $self->get_fragment_object($id)->add_files(@files);

	return $fragment;
} ## end sub add_to_fragment

#####################################################################
# Serialization

=head2 as_string

Loads the file template passed in as the parameter, using this object, 
and returns it as a string.

	# Loads up the merge module template.
	$wxs = $self->as_string('Merge-Module.wxs.tt');

	# Loads up the main template
	$wxs = $self->as_string('Main.wxs.tt');

=cut

sub as_string {
	my $self = shift;
	my $template_file = shift;

	my $tt = Template->new( {
			INCLUDE_PATH => [ $self->dist_dir, $self->wix_dist_dir, ],
			EVAL_PERL    => 1,
		} )
	  || PDWiX::Caught->throw(
		message => 'Template error',
		info    => Template->error(),
	  );

	my $answer;
	my $vars = {
		dist => $self,
		directory_tree =>
		  Perl::Dist::WiX::DirectoryTree2->instance()->as_string(),
	};

	$tt->process( $template_file, $vars, \$answer )
	  || PDWiX::Caught->throw(
		message => 'Template error',
		info    => $tt->error() );
#<<<
	# Delete empty lines.
	## no critic(ProhibitComplexRegexes)
	$answer =~ s{(?>\x0D\x0A?|[\x0A-\x0C\x85\x{2028}\x{2029}])
                            # Replace a linebreak, 
							# (within parentheses is = to \R for 5.8)
				 \s*?       # any whitespace we may be able to catch,
				 (?>\x0D\x0A?|[\x0A-\x0C\x85\x{2028}\x{2029}])}        
				            # and a second linebreak
				{\r\n}msgx; # With one Windows linebreak.
#>>>

	# Combine it all
	return $answer;
} ## end sub as_string


#####################################################################
# Patch Support

# By default only use the default (as a default...)
sub patch_include_path {
	my $self  = shift;
	my $share = File::ShareDir::dist_dir('Perl-Dist-WiX');
	my $path  = catdir( $share, 'default', );
	unless ( -d $path ) {
		PDWiX->throw("Directory $path does not exist");
	}
	return [$path];
}

sub patch_pathlist {
	my $self = shift;
	return File::PathList->new( paths => $self->patch_include_path, );
}

# Cache this
sub patch_template {
	$_[0]->{template_toolkit} ||= Template->new(
		INCLUDE_PATH => $_[0]->patch_include_path,
		ABSOLUTE     => 1,
	);

	return $_[0]->{template_toolkit};
}

sub patch_file {
	my $self     = shift;
	my $file     = shift;
	my $file_tt  = $file . '.tt';
	my $dir      = shift;
	my $to       = catfile( $dir, $file );
	my $pathlist = $self->patch_pathlist;

	# Locate the source file
	my $from    = $pathlist->find_file($file);
	my $from_tt = $pathlist->find_file($file_tt);
	unless ( defined $from and defined $from_tt ) {
		PDWiX->throw(
			"Missing or invalid file $file or $file_tt in pathlist search"
		);
	}

	if ( $from_tt ne q{} ) {

		# Generate the file
		my $hash = _HASH(shift) || {};
		my ( $fh, $output ) =
		  File::Temp::tempfile( 'pdwXXXXXX', TMPDIR => 1 );
		$self->trace_line( 2,
			"Generating $from_tt into temp file $output\n" );
		$self->patch_template->process( $from_tt,
			{ %{$hash}, self => $self }, $fh, )
		  or PDWiX->throw("Template processing failed for $from_tt");

		# Copy the file to the final location
		$fh->close or PDWiX->throw("Could not close: $OS_ERROR");
		$self->_copy( $output => $to );
		unlink $output
		  or PDWiX->throw("Could not delete $output: $OS_ERROR");

	} elsif ( $from ne q{} ) {

		# Simple copy of the regular file to the target location
		$self->_copy( $from => $to );

	} else {
		PDWiX->throw("Failed to find file $file");
	}

	return 1;
} ## end sub patch_file

sub image_drive {
	my $self = shift;
	return substr rel2abs( $self->image_dir() ), 0, 2;
}

sub image_dir_url {
	my $self = shift;
	return URI::file->new( $self->image_dir() )->as_string;
}

# This is a temporary hack
sub image_dir_quotemeta {
	my $self   = shift;
	my $string = $self->image_dir();
	$string =~ s{\\}        # Convert a backslash
				{\\\\}gmsx; ## to 2 backslashes.
	return $string;
}

#####################################################################
# Support Methods

sub _dir {
	return catdir( shift->image_dir(), @_ );
}

sub _file {
	return catfile( shift->image_dir(), @_ );
}

sub _mirror {
	my ( $self, $url, $dir ) = @_;

	my $no_display_trace = 0;
	my (undef, undef, undef, $sub,  undef,
		undef, undef, undef, undef, undef
	) = caller 0;
	if ( $sub eq 'install_par' ) { $no_display_trace = 1; }

	my $file = $url;
	$file =~ s{.+\/} # Delete anything before the last forward slash.
			  {}msx; ## (leaves only the filename.)
	my $target = catfile( $dir, $file );
	if ( $self->offline and -f $target ) {
		return $target;
	}
	if ( $self->offline and not $url =~ m{\Afile://}msx ) {
		PDWiX->throw("Currently offline, cannot download $url.\n");
	}
	File::Path::mkpath($dir);

	$self->trace_line( 2, "Downloading file $url...\n", $no_display_trace );
	if ( $url =~ m{\Afile://}msx ) {

		# Don't use WithCache for files (it generates warnings)
		my $ua = LWP::UserAgent->new;
		my $r = $ua->mirror( $url, $target );
		if ( $r->is_error ) {
			$self->trace_line( 0,
				"    Error getting $url:\n" . $r->as_string . "\n" );
		} elsif ( $r->code == HTTP::Status::RC_NOT_MODIFIED ) {
			$self->trace_line( 2, "(already up to date)\n",
				$no_display_trace );
		}
	} else {

		my $ua = $self->user_agent();
		my $r = $ua->mirror( $url, $target );
		if ( $r->is_error ) {
			$self->trace_line( 0,
				"    Error getting $url:\n" . $r->as_string . "\n" );
		} elsif ( $r->code == HTTP::Status::RC_NOT_MODIFIED ) {
			$self->trace_line( 2, "(already up to date)\n",
				$no_display_trace );
		}
	} ## end else [ if ( $url =~ m{\Afile://}msx)]

	return $target;
} ## end sub _mirror

sub _copy {
	my ( $self, $from, $to ) = @_;
	my $basedir = File::Basename::dirname($to);
	File::Path::mkpath($basedir) unless -e $basedir;
	$self->trace_line( 2, "Copying $from to $to\n" );

	if ( -f $to and not -w $to ) {
		require Win32::File::Object;

		# Make sure it isn't readonly
		my $file = Win32::File::Object->new( $to, 1 );
		my $readonly = $file->readonly;
		$file->readonly(0);

		# Do the actual copy
		File::Copy::Recursive::rcopy( $from, $to )
		  or PDWiX->throw("Copy error: $OS_ERROR");

		# Set it back to what it was
		$file->readonly($readonly);
	} else {
		File::Copy::Recursive::rcopy( $from, $to )
		  or PDWiX->throw("Copy error: $OS_ERROR");
	}
	return 1;
} ## end sub _copy

sub _move {
	my ( $self, $from, $to ) = @_;
	my $basedir = File::Basename::dirname($to);
	File::Path::mkpath($basedir) unless -e $basedir;
	$self->trace_line( 2, "Moving $from to $to\n" );
	File::Copy::Recursive::rmove( $from, $to )
	  or PDWiX->throw("Move error: $OS_ERROR");

	return;
}

sub _pushd {
	my $self = shift;
	my $dir  = catdir(@_);
	$self->trace_line( 2, "Lexically changing directory to $dir...\n" );
	return File::pushd::pushd($dir);
}

sub _build {
	my $self   = shift;
	my @params = @_;
	$self->trace_line( 2,
		join( q{ }, '>', 'Build.bat', @params ) . qq{\n} );
	$self->_run3( 'Build.bat', @params )
	  or PDWiX->throw('build failed');
	PDWiX->throw('build failed (OS error)') if ( $CHILD_ERROR >> 8 );
	return 1;
}

sub _make {
	my $self   = shift;
	my @params = @_;
	$self->trace_line( 2,
		join( q{ }, '>', $self->bin_make, @params ) . qq{\n} );
	$self->_run3( $self->bin_make, @params )
	  or PDWiX->throw('make failed');
	PDWiX->throw('make failed (OS error)') if ( $CHILD_ERROR >> 8 );
	return 1;
}

sub _perl {
	my $self   = shift;
	my @params = @_;

	unless ( -x $self->bin_perl ) {
		PDWiX->throw( q{Can't execute } . $self->bin_perl );
	}

	$self->trace_line( 2,
		join( q{ }, '>', $self->bin_perl, @params ) . qq{\n} );
	$self->_run3( $self->bin_perl, @params )
	  or PDWiX->throw('perl failed');
	PDWiX->throw('perl failed (OS error)') if ( $CHILD_ERROR >> 8 );
	return 1;
} ## end sub _perl

sub _run3 {
	my $self = shift;

	# Remove any Perl installs from PATH to prevent
	# "which" discovering stuff it shouldn't.
	my @path = split /;/ms, $ENV{PATH};
	my @keep = ();
	foreach my $p (@path) {

		# Strip any path that doesn't exist
		next unless -d $p;

		# Strip any path that contains either dmake or perl.exe.
		# This should remove both the ...\c\bin and ...\perl\bin
		# parts of the paths that Vanilla/Strawberry added.
		next if -f catfile( $p, 'dmake.exe' );
		next if -f catfile( $p, 'perl.exe' );

		# Strip any path that contains either unzip or gzip.exe.
		# These two programs cause perl to fail its own tests.
		next if -f catfile( $p, 'unzip.exe' );
		next if -f catfile( $p, 'gzip.exe' );

		push @keep, $p;
	} ## end foreach my $p (@path)

	# Reset the environment
	local $ENV{LIB}      = undef;
	local $ENV{INCLUDE}  = undef;
	local $ENV{PERL5LIB} = undef;
	local $ENV{PATH}     = $self->get_env_path() . q{;} . join q{;}, @keep;

	$self->trace_line( 3, "Path during _run3: $ENV{PATH}\n" );

	# Execute the child process
	return IPC::Run3::run3( [@_], \undef, $self->debug_stdout,
		$self->debug_stderr, );
} ## end sub _run3

sub _convert_name {
	my $name     = shift;
	my @paths    = split m{\/}ms, $name;
	my $filename = pop @paths;
	$filename = q{} unless defined $filename;
	my $local_dirs = @paths ? catdir(@paths) : q{};
	my $local_name = catpath( q{}, $local_dirs, $filename );
	$local_name = rel2abs($local_name);
	return $local_name;
}

sub _extract {
	my ( $self, $from, $to ) = @_;
	File::Path::mkpath($to);
	my $wd = $self->_pushd($to);

	my @filelist;

	$self->trace_line( 2, "Extracting $from...\n" );
	if ( $from =~ m{[.] zip\z}msx ) {
		my $zip = Archive::Zip->new($from);

# I can't just do an extractTree here, as I'm trying to
# keep track of what got extracted.
		my @members = $zip->members();

		foreach my $member (@members) {
			my $filename = $member->fileName();
			$filename = _convert_name($filename)
			  ;                        # Converts filename to Windows format.
			my $status = $member->extractToFileNamed($filename);
			if ( $status != AZ_OK ) {
				PDWiX->throw('Error in archive extraction');
			}
			push @filelist, $filename;
		}

	} elsif ( $from =~ m{ [.] tar [.] gz | [.] tgz}msx ) {
		local $Archive::Tar::CHMOD = 0;
		my @fl = @filelist = Archive::Tar->extract_archive( $from, 1 );
		@filelist = map { catfile( $to, $_ ) } @fl;
		if ( !@filelist ) {
			PDWiX->throw('Error in archive extraction');
		}

	} else {
		PDWiX->throw("Didn't recognize archive type for $from");
	}
	return @filelist;
} ## end sub _extract

sub _extract_filemap {
	my ( $self, $archive, $filemap, $basedir, $file_only ) = @_;

	my @files;

	if ( $archive =~ m{[.] zip\z}msx ) {

		my $zip = Archive::Zip->new($archive);
		my $wd  = $self->_pushd($basedir);
		while ( my ( $f, $t ) = each %{$filemap} ) {
			$self->trace_line( 2, "Extracting $f to $t\n" );
			my $dest = catfile( $basedir, $t );

			my @members = $zip->membersMatching("^\Q$f");

			foreach my $member (@members) {
				my $filename = $member->fileName();
#<<<
				$filename =~
				  s{\A\Q$f}    # At the beginning of the string, change $f 
				   {$dest}msx; # to $dest.
#>>>
				$filename = _convert_name($filename);
				my $status = $member->extractToFileNamed($filename);

				if ( $status != AZ_OK ) {
					PDWiX->throw('Error in archive extraction');
				}
				push @files, $filename;
			} ## end foreach my $member (@members)
		} ## end while ( my ( $f, $t ) = each...)

	} elsif ( $archive =~ m{[.] tar [.] gz | [.] tgz}msx ) {
		local $Archive::Tar::CHMOD = 0;
		my $tar = Archive::Tar->new($archive);
		for my $file ( $tar->get_files ) {
			my $f       = $file->full_path;
			my $canon_f = File::Spec::Unix->canonpath($f);
			for my $tgt ( keys %{$filemap} ) {
				my $canon_tgt = File::Spec::Unix->canonpath($tgt);
				my $t;

#<<<
				# say "matching $canon_f vs $canon_tgt";
				if ($file_only) {
					next unless
					  $canon_f =~ m{\A([^/]+[/])?\Q$canon_tgt\E\z}imsx;
					( $t = $canon_f ) =~ s{\A([^/]+[/])?\Q$canon_tgt\E\z}
										  {$filemap->{$tgt}}imsx;
				} else {
					next unless
					  $canon_f =~ m{\A([^/]+[/])?\Q$canon_tgt\E}imsx;
					( $t = $canon_f ) =~ s{\A([^/]+[/])?\Q$canon_tgt\E}
										  {$filemap->{$tgt}}imsx;
				}
#>>>
				my $full_t = catfile( $basedir, $t );
				$self->trace_line( 2, "Extracting $f to $full_t\n" );
				$tar->extract_file( $f, $full_t );
				push @files, $full_t;
			} ## end for my $tgt ( keys %{$filemap...})
		} ## end for my $file ( $tar->get_files)

	} else {
		PDWiX->throw("Didn't recognize archive type for $archive");
	}

	return @files;
} ## end sub _extract_filemap

# Convert a .dll to an .a file
sub _dll_to_a {
	my $self   = shift;
	my %params = @_;
	unless ( $self->bin_dlltool ) {
		PDWiX->throw('dlltool has not been installed');
	}

	my @files;

	# Source file
	my $source = $params{source};
	if ( $source and not( $source =~ /[.]dll\z/msx ) ) {
		PDWiX::Parameter->throw(
			parameter => 'source',
			where     => '->_dll_to_a'
		);
	}

	# Target .dll file
	my $dll = $params{dll};
	unless ( $dll and $dll =~ /[.]dll/msx ) {
		PDWiX::Parameter->throw(
			parameter => 'dll',
			where     => '->_dll_to_a'
		);
	}

	# Target .def file
	my $def = $params{def};
	unless ( $def and $def =~ /[.]def\z/msx ) {
		PDWiX::Parameter->throw(
			parameter => 'def',
			where     => '->_dll_to_a'
		);
	}

	# Target .a file
	my $_a = $params{a};
	unless ( $_a and $_a =~ /[.]a\z/msx ) {
		PDWiX::Parameter->throw(
			parameter => 'a',
			where     => '->_dll_to_a'
		);
	}

	# Step 1 - Copy the source .dll to the target if needed
	unless ( ( $source and -f $source ) or -f $dll ) {
		PDWiX::Parameter->throw(
			parameter => 'source or dll: Need one of '
			  . 'these two parameters, and the file needs to exist',
			where => '->_dll_to_a'
		);
	}

	if ($source) {
		$self->_move( $source => $dll );
		push @files, $dll;
	}

	# Step 2 - Generate the .def from the .dll
  SCOPE: {
		my $bin = $self->bin_pexports;
		unless ($bin) {
			PDWiX->throw('pexports has not been installed');
		}
		my $ok = !system "$bin $dll > $def";
		unless ( $ok and -f $def ) {
			PDWiX->throw('pexports failed to generate .def file');
		}

		push @files, $def;
	} ## end SCOPE:

	# Step 3 - Generate the .a from the .def
  SCOPE: {
		my $bin = $self->bin_dlltool;
		unless ($bin) {
			PDWiX->throw('dlltool has not been installed');
		}
		my $ok = !system "$bin -dllname $dll --def $def --output-lib $_a";
		unless ( $ok and -f $_a ) {
			PDWiX->throw('dlltool failed to generate .a file');
		}

		push @files, $_a;
	} ## end SCOPE:

	return @files;
} ## end sub _dll_to_a

sub _make_path {
	my $class = shift;
	my $dir = rel2abs( shift );
	
	File::Path::mkpath($dir) unless -d $dir;
	unless ( -d $dir ) {
		PDWiX->throw("Failed to create directory $dir");
	}
	return $dir;
}

sub _remake_path {
	my $class = shift;
	my $dir = rel2abs( shift );
	File::Remove::remove( \1, $dir ) if -d $dir;
	File::Path::mkpath($dir);

	unless ( -d $dir ) {
		PDWiX->throw("Failed to recreate directory $dir");
	}
	return $dir;
}


1;

__END__

=pod

=head1 DIAGNOSTICS

See L<Perl::Dist::WiX::Diagnostics|Perl::Dist::WiX::Diagnostics> for a list of
exceptions that this module can throw.

=for readme continue

=head1 DEPENDENCIES

Perl 5.8.1 is the mimimum version of perl that this module will run on.

Other modules that this module depends on are a working version of 
L<Alien::WiX|Alien::WiX>, L<Data::Dump::Streamer|Data::Dump::Streamer> 2.08, 
L<Data::UUID|Data::UUID> 1.149, L<Devel::StackTrace|Devel::StackTrace> 1.20, 
L<Exception::Class|Exception::Class> 1.22, L<File::ShareDir|File::ShareDir> 
1.00, L<IO::String|IO::String> 1.08, L<List::MoreUtils|List::MoreUtils> 0.07, 
L<Module::CoreList|Module::CoreList> 2.17, 
L<Object::InsideOut|Object::InsideOut> 3.53, L<Perl::Dist|Perl::Dist> 1.14, 
L<Process|Process> 0.26, L<Readonly|Readonly> 1.03, L<URI|URI> 1.35, and 
L<Win32|Win32> 0.35.

=for readme stop

=head1 TODO

=over

=item 1.

Add the ability to build in a 32 or 64 bit toolchain using gcc 4.x.x.

=item 2.

Make the perl distribution relocatable.

=back

=head1 BUGS AND LIMITATIONS (SUPPORT)

Bugs should be reported via: 

1) The CPAN bug tracker at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Dist-WiX>
if you have an account there.

2) Email to E<lt>bug-Perl-Dist-WiX@rt.cpan.orgE<gt> if you do not.

For other issues, contact the topmost author.

=head1 AUTHORS

Curtis Jewell E<lt>csjewell@cpan.orgE<gt>

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Perl::Dist|Perl::Dist>, L<Perl::Dist::Inno|Perl::Dist::Inno>, 
L<http://ali.as/>, L<http://csjewell.comyr.com/perl/>

=for readme continue

=head1 COPYRIGHT AND LICENSE

Copyright 2009 Curtis Jewell.

Copyright 2008 - 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
