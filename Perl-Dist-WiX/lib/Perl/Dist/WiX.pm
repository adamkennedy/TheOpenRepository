package Perl::Dist::WiX;

=pod

=head1 NAME

Perl::Dist::WiX - Experimental 4th generation Win32 Perl distribution builder

=head1 DESCRIPTION

This package is the experimental upgrade to Perl::Dist based on Windows 
Install XML technology, instead of Inno Setup.

=head1 METHODS

=cut

#<<<

use     5.008;
use     strict;
use     warnings;
use     Carp                  qw( croak                   );
use     Archive::Zip          qw( :ERROR_CODES            );
use     List::MoreUtils       qw( any                     );
use     Params::Util          qw( _HASH _STRING _INSTANCE );
use     File::Spec::Functions
  qw( catdir catfile catpath tmpdir splitpath rel2abs curdir );
use     Archive::Tar     1.42 qw();
use     File::Remove          qw();
use     File::pushd           qw();
use     File::ShareDir        qw();
use     File::Copy::Recursive qw();
use     File::PathList        qw();
use     HTTP::Status          qw();
use     IO::String            qw();
use     LWP::UserAgent        qw();
use     LWP::Online           qw();
use     PAR::Dist             qw();
use     SelectSaver           qw();
use     Template              qw();
use     Module::CoreList 2.17 qw();
require Perl::Dist::WiX::Installer;
require Perl::Dist::WiX::Filelist;
require Perl::Dist::WiX::StartMenuComponent;
#>>>

use Object::Tiny qw{
  perl_version
  portable
  exe
  msi
  zip
  binary_root
  offline
  temp_dir
  download_dir
  image_dir
  modules_dir
  license_dir
  fragment_dir
  build_dir
  checkpoint_dir
  bin_perl
  bin_make
  bin_pexports
  bin_dlltool
  env_path
  debug_stdout
  debug_stderr
  output_file
  perl_version_corelist
  cpan
  force
  checkpoint_before
  checkpoint_after
  filters
  build_number
  beta_number
  trace
};

#<<<
use Perl::Dist::Asset               1.12 ();
use Perl::Dist::Asset::Binary       1.12 ();
use Perl::Dist::Asset::Library      1.12 ();
use Perl::Dist::Asset::Perl         1.12 ();
use Perl::Dist::Asset::Distribution 1.12 ();
use Perl::Dist::Asset::Module       1.12 ();
use Perl::Dist::Asset::PAR          1.12 ();
use Perl::Dist::Asset::File         1.12 ();
use Perl::Dist::Asset::Website      1.12 ();
use Perl::Dist::Asset::Launcher     1.12 ();
use Perl::Dist::Util::Toolchain     1.12 ();

use vars qw( $VERSION @ISA );
BEGIN {
    use version; $VERSION = qv('0.13_02');
    @ISA     = 'Perl::Dist::WiX::Installer';
}
#>>>

#####################################################################
# Constructor

=pod

=head2 new

The B<new> method creates a new Perl Distribution build as an object.

Each object is used to create a single distribution, and then should be
discarded.

Although there are about 30 potential constructor arguments that can be
provided, most of them are automatically resolved and exist for overloading
puposes only, or they revert to sensible defaults and generally never need
to be modified.

The following is an example of the most likely attributes that will be
specified.

  my $build = Perl::Dist::WiX->new(
      image_dir => 'C:\vanilla',
      temp_dir  => 'C:\tmp\vp',
	  msi_directory_tree_additions => [ qw(
        c\bin\program
        perl\lib\Acme
      )],
      cpan      => URI->new(('file://C|/minicpan/')),
  );

Attributes that are required to be set are marked as I<(required)> 
below.  They may often be set by subclasses.

=over 4

=item * image_dir I<(required)>

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
results.

=item * temp_dir

B<Perl::Dist::WiX> needs a series of temporary directories while
it is running the build, including places to cache downloaded files,
somewhere to expand tarballs to build things, and somewhere to put
debugging output and the final installer zip and exe files.

The C<temp_dir> param specifies the root path for where these
temporary directories should be created.

For convenience it is best to make these short paths with simple
names, near the root.

This parameter defaults to a subdirectory of $ENV{TEMP} if not specified.

=item * force

The C<force> parameter determines if perl and perl modules are 
tested upon installation.  If this parameter is true, then no 
testing is done.

=item * trace

The C<trace> parameter sets the level of tracing that is output.

Setting this parameter to 0 prints out only MAJOR stuff and errors.

Setting this parameter to 2 or above will print out the level as the 
first thing on the line.

Setting this parameter to 3 or above will print out the filename and 
line number after the trace level on those lines that require a trace 
level of 3 or above to print.

Setting this parameter to 5 or above will print out the filename and 
line number on every line.

Default is 1 if not set.

=item * perl_version

The C<perl_version> parameter specifies what version of perl is 
downloaded and built.  Legal values for this parameter are '588', 
'589', and '5100' (for 5.8.8, 5.8.9, and 5.10.0, respectively.)

This parameter defaults to '5100' if not specified.

=item * cpan

The C<cpan> param provides a path to a CPAN or minicpan mirror that
the installer can use to fetch any needed files during the build
process.

The param should be a L<URI> object to the root of the CPAN repository,
including trailing slash.

If you are online and no C<cpan> param is provided, the value will
default to the L<http://cpan.strawberryperl.com> repository as a
convenience.

=item * portable

The optional boolean C<portable> param is used to indicate that the
distribution is intended for installation on a portable storable
device.

=item * zip

The optional boolean C<zip> param is used to indicate that a zip
distribution package should be created.

=item * msi

The optional boolean C<msi> param is used to indicate that a Windows
Installer distribution package (otherwise known as an msi file) should 
be created.

=item * exe

The optional boolean C<exe> param is deprecated.

=item * checkpoint_after

Stops the installation at the stage that has this number. 

=item * checkpoint_before

Starts a saved installation at the stage that has this number.

=item * app_id I<(required)>

The C<app_id> parameter provides the base identifier of the 
distribution that is used in constructing filenames.  This 
must be a legal Perl identifier (no spaces, for example) and 
is required.

=item * app_name I<(required)>

The C<app_name> parameter provides the name of the distribution. 
This is required.

=item * app_publisher I<(required)>

The C<app_publisher> parameter provides the publisher of the 
distribution. 

=item * app_publisher_url I<(required)>

The C<app_publisher_url> parameter provides the URL of the publisher 
of the distribution.

=item * default_group_name

The name for the Start menu group this program 
installs its shortcuts to.  Defaults to app_name if none is provided.

=item * msi_debug

The optional boolean C<msi_debug> parameter is used to indicate that
a debugging MSI (one that creates a log in $ENV{TEMP}) will be created if 
C<msi> is also true.

=item * build_number I<(required)>

The required integer C<build_number> parameter is used to set the build number
portion of the distribution's version number, and is used in constructing filenames.

=item * beta_number

The optional integer C<beta_number> parameter is used to set the beta number
portion of the distribution's version number (if this is a beta distribution), 
and is used in constructing filenames.

It defaults to 0 if not set, which will construct distributions without a beta
number.

=item * msi_license_file

The optional C<msi_license_file> parameter specifies the location of an 
.rtf or .txt file to be displayed at the point where the MSI asks you 
to accept a license.

Perl::Dist::WiX provides a default one if none is supplied here.

=item * msi_banner_top

The optional C<msi_banner_top> parameter specifies the location of a 
493x58 .bmp file that is  used on the top of most of the dialogs in 
the MSI file.

WiX will use its default if no file is supplied here.

=item * msi_banner_side

The optional C<msi_banner_side> parameter specifies the location of 
a 493x312 .bmp file that is used in the introductory dialog in the MSI 
file.

WiX will use its default if no file is supplied here.

=item * msi_help_url

The optional C<msi_help_url> parameter specifies the URL that 
Add/Remove Programs directs you to for support when you click 
the "Click here for support information." text.

=item * msi_readme_file

The optional C<msi_readme_file> parameter specifies a .txt or .rtf file 
or a URL (TODO: check) that is linked in Add/Remove Programs in the 
"Click here for support information." text.

=item * msi_product_icon

The optional C<msi_product_icon> parameter specifies the icon that is 
used in Add/Remove Programs for this MSI file.

=item * msi_directory_tree_additions

The optional C<msi_directory_tree_additions> parameter is a reference 
to an array of directories under image_dir (i.e. perl\lib\Module, as 
opposed to C:\distribution\perl\lib\module) that need to be in the 
initial directory tree because they are used by more than one fragment.

If upon running the distribution module, you see LGHT0091 or LGHT0130 
errors at the end that refer to directories, add the applicable 
directories to this parameter.

=back

The C<new> constructor returns a B<Perl::Dist> object, which you
should then call C<run> on to generate the distribution.

=cut

sub new {
    my $class  = shift;
    my %params = @_;

    # Apply some defaults
    unless ( defined $params{trace} ) {
        $params{trace} = 1;
    }

    # Announce that we're staring.
    my $time = localtime;
    if ( $params{trace} > 1 ) { print '[0] '; }
    print "Starting build at $time.\n";

    # Apply more defaults
    unless ( defined $params{binary_root} ) {
        $params{binary_root} = 'http://strawberryperl.com/package';
    }
    unless ( defined $params{temp_dir} ) {
        $params{temp_dir} = catdir( tmpdir(), 'perldist' );
    }
    unless ( defined $params{download_dir} ) {
        $params{download_dir} = catdir( $params{temp_dir}, 'download' );
        File::Path::mkpath( $params{download_dir} );
    }
    unless ( defined $params{build_dir} ) {
        $params{build_dir} = catdir( $params{temp_dir}, 'build' );
        $class->remake_path( $params{build_dir} );
    }
    unless ( defined $params{output_dir} ) {
        $params{output_dir} = catdir( $params{temp_dir}, 'output' );
        if ( $params{trace} > 0 ) {
            if ( $params{trace} > 1 ) { print '[1] '; }
            print "Wait a second while we empty the output directory...\n";
        }
        $class->remake_path( $params{output_dir} );
    }
    unless ( defined $params{fragment_dir} ) {
        $params{fragment_dir} =        # To store the WiX fragments in.
          catdir( $params{output_dir}, 'fragments' );
        File::Path::mkpath( $params{fragment_dir} );
    }
    if ( defined $params{image_dir} ) {
        $class->remake_path( $params{image_dir} );
    }
    unless ( defined $params{perl_version} ) {
        $params{perl_version} = '5100';
    }

    # Hand off to the parent class
    my $self = $class->SUPER::new( %params );

    # Check the version of Perl to build
    unless ( $self->build_number ) {
        croak "Failed to resolve build_number";
    }
    unless ( $self->beta_number ) {
        $self->{beta_number} = 0;
    }
    unless ( $self->perl_version_literal ) {
        croak "Failed to resolve perl_version_literal";
    }
    unless ( $self->perl_version_human ) {
        croak "Failed to resolve perl_version_human";
    }
    unless ( $self->can( 'install_perl_' . $self->perl_version ) ) {
        croak( "$class does not support Perl " . $self->perl_version );
    }

    # Find the core list
    my $corelist_version = $self->perl_version_literal + 0;
    $self->{perl_version_corelist} =
      $Module::CoreList::version{$corelist_version};
    unless ( _HASH( $self->{perl_version_corelist} ) ) {
        croak( "Failed to resolve Module::CoreList hash for "
              . $self->perl_version_human );
    }

    # Apply more defaults
    unless ( defined $self->{force} ) {
        $self->{force} = 0;
    }
    unless ( defined $self->debug_stdout ) {
        $self->{debug_stdout} = catfile( $self->output_dir, 'debug.out' );
    }
    unless ( defined $self->debug_stderr ) {
        $self->{debug_stderr} = catfile( $self->output_dir, 'debug.err' );
    }

    # Auto-detect online-ness if needed
    unless ( defined $self->offline ) {
        $self->{offline} = LWP::Online::offline();
    }

    unless ( defined $self->exe ) {
        $self->{exe} = 0;              #  Can't make an exe yet from WiX alone.
    }
    unless ( defined $self->zip ) {
        $self->{zip} = $self->portable ? 1 : 0;
    }
    unless ( defined $self->msi ) {
        $self->{msi} = 1;              # Goal of Perl::Dist::WiX is to make an MSI.
    }
    unless ( defined $self->checkpoint_before ) {
        $self->{checkpoint_before} = 0;
    }
    unless ( defined $self->checkpoint_after ) {
        $self->{checkpoint_after} = 0;
    }

    # Normalize some params
    $self->{offline}  = !!$self->offline;
    $self->{force}    = !!$self->force;
    $self->{portable} = !!$self->portable;
    $self->{exe}      = !!$self->exe;
    $self->{zip}      = !!$self->zip;
    $self->{msi}      = !!$self->msi;

    # Handle portable special cases
    if ( $self->portable ) {
        $self->{exe} = 0;
        $self->{msi} = 0;
    }

    # If we are online and don't have a cpan repository,
    # use cpan.strawberryperl.com as a default.
    if ( !$self->offline and !$self->cpan ) {
        $self->{cpan} = URI->new( 'http://cpan.strawberryperl.com/' );
    }

    # Check params
    unless ( _STRING( $self->download_dir ) ) {
        croak( "Missing or invalid download_dir param" );
    }
    unless ( defined $self->modules_dir ) {
        $self->{modules_dir} = catdir( $self->download_dir, 'modules' );
    }
    unless ( _STRING( $self->modules_dir ) ) {
        croak( "Invalid modules_dir param" );
    }
    unless ( _STRING( $self->image_dir ) ) {
        croak( "Missing or invalid image_dir param" );
    }
    if ( $self->image_dir =~ /\s/ ) {
        croak( "Spaces are not allowed in image_dir" );
    }
    unless ( defined $self->license_dir ) {
        $self->{license_dir} = catdir( $self->image_dir, 'licenses' );
    }
    unless ( _STRING( $self->license_dir ) ) {
        croak( "Invalid license_dir param" );
    }
    unless ( _STRING( $self->build_dir ) ) {
        croak( "Missing or invalid build_dir param" );
    }
    if ( $self->build_dir =~ /\s/ ) {
        croak( "Spaces are not allowed in build_dir" );
    }
    unless ( _INSTANCE( $self->user_agent, 'LWP::UserAgent' ) ) {
        croak( "Missing or invalid user_agent param" );
    }
    unless ( _INSTANCE( $self->cpan, 'URI' ) ) {
        croak( "Missing or invalid cpan param" );
    }
    unless ( $self->cpan->as_string =~ /\/$/ ) {
        croak( "Missing trailing slash in cpan param" );
    }

    # Clear the previous build
    if ( -d $self->image_dir ) {
        $self->trace_line( 1,
            "Removing previous " . $self->image_dir . "\n" );
        File::Remove::remove( \1, $self->image_dir );
    } else {
        $self->trace_line( 1,
            "No previous " . $self->image_dir . " found\n" );
    }

    # Initialize the build
    for my $d (
        $self->download_dir, $self->image_dir,
        $self->modules_dir,  $self->license_dir,
      )
    {
        next if -d $d;
        File::Path::mkpath( $d );
    }

    # Initialize filters.
    my @filters_array;
#<<<
    push @filters_array,
               $self->temp_dir . q{\\},
      catdir ( $self->image_dir, qw{ perl man         } ) . q{\\},
      catdir ( $self->image_dir, qw{ perl html        } ) . q{\\},
      catdir ( $self->image_dir, qw{ c    man         } ) . q{\\},
      catdir ( $self->image_dir, qw{ c    doc         } ) . q{\\},
      catdir ( $self->image_dir, qw{ c    info        } ) . q{\\},
      catdir ( $self->image_dir, qw{ c    contrib     } ) . q{\\},
      catdir ( $self->image_dir, qw{ c    html        } ) . q{\\},
      catdir ( $self->image_dir, qw{ c    examples    } ) . q{\\},
      catdir ( $self->image_dir, qw{ c    manifest    } ) . q{\\},
      catdir ( $self->image_dir, qw{ cpan sources     } ) . q{\\},
      catdir ( $self->image_dir, qw{ cpan build       } ) . q{\\},
      catfile( $self->image_dir, qw{ c    COPYING     } ),
      catfile( $self->image_dir, qw{ c    COPYING.LIB } ),
      ;
#>>>

    $self->{filters} = \@filters_array;

    # Get environment started.
    $self->{env_path} = [];

    $self->add_env( 'TERM',        'dumb' );
    $self->add_env( 'FTP_PASSIVE', '1' );

    return $self;
} ## end sub new

#####################################################################
# Upstream Binary Packages (Mirrored)

my %PACKAGES = (
    'dmake'         => 'dmake-4.8-20070327-SHAY.zip',
    'gcc-core'      => 'gcc-core-3.4.5-20060117-3.tar.gz',
    'gcc-g++'       => 'gcc-g++-3.4.5-20060117-3.tar.gz',
    'mingw-make'    => 'mingw32-make-3.81-2.tar.gz',
    'binutils'      => 'binutils-2.17.50-20060824-1.tar.gz',
    'mingw-runtime' => 'mingw-runtime-3.13.tar.gz',
    'w32api'        => 'w32api-3.10.tar.gz',
    'libiconv-dep'  => 'libiconv-1.9.2-1-dep.zip',
    'libiconv-lib'  => 'libiconv-1.9.2-1-lib.zip',
    'libiconv-bin'  => 'libiconv-1.9.2-1-bin.zip',
    'expat'         => 'expat-2.0.1-vanilla.zip',
    'gmp'           => 'gmp-4.2.1-vanilla.zip',
);

sub binary_file {
    unless ( $PACKAGES{ $_[1] } ) {
        croak( "Unknown package '$_[1]'" );
    }
    return $PACKAGES{ $_[1] };
}

sub binary_url {
    my $self = shift;
    my $file = shift;

    # Check parameters.
    unless ( _STRING( $file ) ) {
        croak( "Missing or invalid file param" );
    }

    unless ( $file =~ /\.(zip|gz|tgz)$/i ) {

        # Shorthand, map to full file name
        $file = $self->binary_file( $file, @_ );
    }
    return $self->binary_root . '/' . $file;
} ## end sub binary_url

=head2 Accessors

    $id = $dist->bin_candle; 

Accessors will return a specified portion of the distribution state.

If it can also be set as a parameter to C<new>, it is marked as I<(also C<new> parameter)> below.

=head3 binary_root

I<(also C<new> parameter)>

The C<binary_root> accessor returns the URL (as a string, not including the 
filename) where the distribution will be uploaded.

Defaults to 'http://strawberryperl.com/package'.

=head3 modules_dir

I<(also C<new> parameter)>

The directory where the modules for the distribution will be downloaded to. 

Defaults to C<download_dir> . '\modules'.

=head3 license_dir

I<(also C<new> parameter)>

The subdirectory of image_dir where the licenses for the different 
portions of the distribution will be copied to. 

Defaults to C<image_dir> . '\licenses'.

=head3 build_dir

I<(also C<new> parameter)>

The directory where the source files for the distribution will be 
extracted and built from.

Defaults to C<temp_dir> . '\build'.

=head3 checkpoint_dir

I<(also C<new> parameter)>

The directory where Perl::Dist::WiX will store its checkpoints. 

Defaults to C<temp_dir> . '\checkpoint'.

=head3 bin_perl, bin_make, bin_pexports, bin_dlltool

The location of perl.exe, dmake.exe, pexports.exe, and dlltool.exe.

These only are available (not undef) once the appropriate packages 
are installed.

=head3 env_path

An arrayref storing the different directories under C<image_dir> that 
need to be added to the PATH.

=head3 debug_stdout, debug_stderr

The files where STDOUT and STDERR is redirected to to receive the output
of make and perl.

Defaults to C<output_dir> . '\debug.out' and 
C<output_dir> . '\debug.err'

=head3 perl_version_corelist

A hash containing the versions of the core modules in the version of 
perl being distributed.  Retrieved from L<Module::Corelist>.

=head3 output_file

The list of distributions created as an array reference.

=head3 filters

Provides an array reference of files and directories that will not be
installed.

Initialized in C<new>.

=head3 dist_dir

Provides a shortcut to the location of the shared files directory.

Returns a directory as a string or dies on error.

=cut

sub dist_dir {
    File::ShareDir::dist_dir( 'Perl-Dist-WiX' );
}

#####################################################################
# Documentation for accessors

=pod

=head3 offline

The B<Perl::Dist> module has limited ability to build offline, if all
packages have already been downloaded and cached.

The connectedness of the Perl::Dist object is checked automatically
be default using L<LWP::Online>. It can be overidden by providing an
offline param to the constructor.

The C<offline> accessor returns true if no connection to "the internet"
is available and the object will run in offline mode, or false
otherwise.

=head3 download_dir 

I<(also C<new> parameter)>

The C<download_dir> accessor returns the path to the directory that
packages of various types will be downloaded and cached to.

An explicit value can be provided via a C<download_dir> param to the
constructor. Otherwise the value is derived from C<temp_dir>.

=head3 image_dir

I<(also C<new> parameter)>

The C<image_dir> accessor returns the path to the built distribution
image. That is, the directory in which the build C/Perl code and
modules will be installed on the build server.

At the present time, this is also the path to which Perl will be
installed on the user's machine via the C<source_dir> accessor,
which is an alias to the L<Perl::Dist::WiX::Installer> method
C<source_dir>. (although theoretically they can be different,
this is likely to break the user's Perl install)

=cut

#####################################################################
# Checkpoint Support

sub checkpoint_task {
    my $self = shift;
    my $task = shift;
    my $step = shift;

    # Are we loading at this step?
    if ( $self->checkpoint_before == $step ) {
        $self->checkpoint_load;
    }

    # Skip if we are loading later on
    unless ( $self->checkpoint_before > $step ) {
        my $t = time;
        $self->$task();
        $self->trace_line( 0,
            "Completed $task in " . ( time - $t ) . " seconds\n" );
    }

    # Are we saving at this step
    if ( $self->checkpoint_after == $step ) {
        $self->checkpoint_save;
    }

    return $self;
} ## end sub checkpoint_task

sub checkpoint_file {
    catfile( $_[0]->checkpoint_dir, 'self.dat' );
}

sub checkpoint_self {
    die "CODE INCOMPLETE";
}

sub checkpoint_save {
    my $self = shift;
    unless ( $self->temp_dir ) {
        die "Checkpoints require a temp_dir to be set";
    }

    # Clear out any existing checkpoint
    $self->trace_line( 1, "Removing old checkpoint\n" );
    $self->{checkpoint_dir} = catfile( $self->temp_dir, 'checkpoint' );
    $self->remake_path( $self->checkpoint_dir );

    # Copy the paths into the checkpoint directory
    $self->trace_line( 1, "Copying checkpoint directories...\n" );
    foreach my $dir ( qw{ build_dir download_dir image_dir output_dir } ) {
        my $from = $self->$dir();
        my $to = catdir( $self->checkpoint_dir, $dir );
        $self->_copy( $from => $to );
    }

    # Store the main object.
    # Blank the checkpoint values to prevent load/save loops, and remove
    # things we can recreate later.
    my $copy = {
        %$self,
        checkpoint_before => 0,
        checkpoint_after  => 0,
        user_agent        => undef,
    };
    Storable::nstore( $copy, $self->checkpoint_file );

    return 1;
} ## end sub checkpoint_save

sub checkpoint_load {
    my $self = shift;
    unless ( $self->temp_dir ) {
        die "Checkpoints require a temp_dir to be set";
    }

    # Does the checkpoint exist
    $self->trace_line( 1, "Removing old checkpoint\n" );
    $self->{checkpoint_dir} =
      File::Spec->catfile( $self->temp_dir, 'checkpoint', );
    unless ( -d $self->checkpoint_dir ) {
        die "Failed to find checkpoint directory";
    }

    # Load the stored hash over our object
    my $stored = Storable::retrieve( $self->checkpoint_file );
    %$self = %$stored;

    # Pull all the directories out of the storage
    $self->trace_line( "Restoring checkpoint directories...\n" );
    foreach my $dir ( qw{ build_dir download_dir image_dir output_dir } ) {
        my $from = File::Spec->catdir( $self->checkpoint_dir, $dir );
        my $to = $self->$dir();
        File::Remove::remove( $to );
        $self->_copy( $from => $to );
    }

    return 1;
} ## end sub checkpoint_load

sub source_dir {
    return $_[0]->image_dir;
}

# Default the versioned name to an unversioned name
sub app_ver_name {
    my $self = shift;
    if ( $self->{app_ver_name} ) {
        return $self->{app_ver_name};
    }
    return $self->app_name . ' ' . $self->perl_version_human;
}

# Default the output filename to the id plus the current date
sub output_base_filename {
    my $self = shift;
    if ( $self->{output_base_filename} ) {
        return $self->{output_base_filename};
    }
    return
        $self->app_id . '-'
      . $self->perl_version_human . '-'
      . $self->output_date_string;
}

#####################################################################
# Perl::Dist::WiX Main Methods

=pod

=head3 perl_version

The C<perl_version> accessor returns the shorthand perl version
as a string (consisting of the three-part version with dots
removed).

Thus Perl 5.8.8 will be "588" and Perl 5.10.0 will return "5100".

=head3 perl_version_literal

The C<perl_version_literal> method returns the literal numeric Perl
version for the distribution.

For Perl 5.8.8 this will be '5.008008', Perl 5.8.9 will be '5.008009',
and for Perl 5.10.0 this will be '5.010000'.

=cut

sub perl_version_literal {
    return {
        588  => '5.008008',
        589  => '5.008009',
        5100 => '5.010000',
      }->{ $_[0]->perl_version }
      || 0;
}

=pod

=head3 perl_version_human

The C<perl_version_human> method returns the "marketing" form
of the Perl version.

This will be either '5.8.8', '5.8.9' or '5.10.0'.

=cut

sub perl_version_human {
    return {
        588  => '5.8.8',
        589  => '5.8.9',
        5100 => '5.10.0',
      }->{ $_[0]->perl_version }
      || 0;
}

#####################################################################
# Top Level Process Methods

sub prepare { 1 }

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
        $self->trace_line( "No msi or zip target, nothing to do" );
        return 1;
    }

    # Don't buffer
    $| = 1;

    # Install the core C toolchain
    $self->checkpoint_task( install_c_toolchain => 1 );

    # Install any additional C libraries
    $self->checkpoint_task( install_c_libraries => 2 );

    # Install the Perl binary
    $self->checkpoint_task( install_perl => 3 );

    # Install additional Perl modules
    $self->checkpoint_task( install_perl_modules => 4 );

    # Install the Win32 extras
    $self->checkpoint_task( install_win32_extras => 5 );

    # Apply optional portability support
    $self->checkpoint_task( install_portable => 6 ) if $self->portable;

    # Remove waste and temporary files
    $self->checkpoint_task( remove_waste => 7 );

    # Install any extra custom non-Perl software on top of Perl.
    # This is primarily added for the benefit of Parrot.
    $self->checkpoint_task( install_custom => 8 );

    # Write out the distributions
    $self->checkpoint_task( write => 9 );

    # Finished
    $self->trace_line( 0,
            "Distribution generation completed in "
          . ( time - $start )
          . " seconds\n" );
    foreach my $file ( @{ $self->output_file } ) {
        $self->trace_line( 0, "Created distribution $file\n" );
    }

    return 1;
} ## end sub run

=head2 Routines used by C<run>

=head3 install_custom

The C<install_custom> method is an empty install stub provided
to allow sub-classed distributions to add B<vastly> different
additional packages on top of Strawberry Perl.

For example, this class is used by the Parrot distribution builder
(which needs to sit on a full Strawberry install).

Notably, the C<install_custom> method comes AFTER C<remove_waste>, so that the
file deletion logic in C<remove_waste> won't accidntally delete files that
may result in a vastly more damaging effect on the custom software.

Returns true, or throws an error on exception.

=cut

sub install_custom {
    return 1;
}

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

    # Core compiler
    $self->install_gcc;

    # C Utilities
    $self->install_mingw_make;
    $self->install_binutils;
    $self->install_pexports;

    # Install support libraries
    $self->install_mingw_runtime;
    $self->install_win32api;

    # Set up the environment variables for the binaries
    $self->add_env_path( 'c', 'bin' );

    return 1;
} ## end sub install_c_toolchain

=head3 install_c_libraries

The C<install_c_libraries> method is an empty install stub provided
to allow sub-classed distributions to add B<vastly> different
additional packages on top of Strawberry Perl.

Returns true, or throws an error on exception.

=cut

# No additional modules by default
sub install_c_libraries {
    my $class = shift;
    if ( $class eq __PACKAGE__ ) {
        $class->trace_line( 1, "install_c_libraries: Nothing to do\n" );
    }
    return 1;
}

# Install Perl 5.10.0 by default.
# Just hand off to the larger set of Perl install methods.
sub install_perl {
    my $self                = shift;
    my $install_perl_method = "install_perl_" . $self->perl_version;
    unless ( $self->can( $install_perl_method ) ) {
        croak(
            "Cannot generate perl, missing $install_perl_method method in "
              . ref( $self ) );
    }
    $self->$install_perl_method( @_ );

    $self->add_to_fragment('perl', [ catfile($self->image_dir, qw(perl lib perllocal.pod)) ]);
    
    return $self;
} ## end sub install_perl

sub install_perl_toolchain {
    my $self = shift;
    my $toolchain =
      @_
      ? _INSTANCE( $_[0], 'Perl::Dist::Util::Toolchain' )
      : Perl::Dist::Util::Toolchain->new(
        perl_version => $self->perl_version_literal, );
    unless ( $toolchain ) {
        die( "Did not provide a toolchain resolver" );
    }

    # Get the regular Perl to generate the list.
    # Run it in a separate process so we don't hold
    # any permanent CPAN.pm locks.
    $toolchain->delegate;
    if ( $toolchain->{errstr} ) {
        die( "Failed to generate toolchain distributions" );
    }

    # Install the toolchain dists
    foreach my $dist ( @{ $toolchain->{dists} } ) {
        my $automated_testing = 0;
        my $release_testing   = 0;
        my $force             = $self->force;
        if (( $dist =~ /Test-Simple/ ) and ($self->perl_version eq '588')) {

            # Can't rely on t/threads.t to work right
            # inside the harness. 
            $force = 1;
        }
        if ( $dist =~ /Scalar-List-Util/ ) {

            # Does something weird with tainting
            $force = 1;
        }
        if ( $dist =~ /URI-/ ) {

            # Can't rely on t/heuristic.t not finding a www.perl.bv
            # because some ISP's use DNS redirectors for unfindable 
            # sites.
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
            release_testing   => $release_testing,
        );
    } ## end foreach my $dist ( @{ $toolchain...

    return 1;
} ## end sub install_perl_toolchain

sub install_cpan_upgrades {
    my $self = shift;
    unless ( $self->bin_perl ) {
        croak( "Cannot install CPAN modules yet, perl is not installed" );
    }

    if ( $self->perl_version =~ m(\A510)) {

        # 5.10.x versions need these modules installed BEFORE the upgrade...
        $self->install_distribution(
            name => 'ARANDAL/Pod-Simple-3.07.tar.gz', 
            makefilepl_param  => ['INSTALLDIRS=perl']
        )->install_distribution(
            name => 'MSERGEANT/Time-Piece-1.13.tar.gz', 
            makefilepl_param  => ['INSTALLDIRS=perl']
        );
    }
    
    my $fl2 = Perl::Dist::WiX::Filelist->new->readdir(
        catdir( $self->image_dir, 'perl' ) );
    
    # Generate the CPAN installation script
    my $cpan_string = <<"END_PERL";
print "Loading CPAN...\\n";
use CPAN;
CPAN::HandleConfig->load unless \$CPAN::Config_loaded++;
print "Upgrading all out of date CPAN modules...\\n";
print "\\\$ENV{PATH} = '\$ENV{PATH}'\\n";
CPAN::Shell->upgrade;
print "Completed upgrade of all modules\\n";
exit(0);
END_PERL

    # Dump the CPAN script to a temp file and execute
    $self->trace_line( 1, "Running upgrade of all modules\n" );
    my $cpan_file = catfile( $self->build_dir, 'cpan_string.pl' );
  SCOPE: {
        open( CPAN_FILE, '>', $cpan_file ) or die "open: $!";
        print CPAN_FILE $cpan_string or die "print: $!";
        close( CPAN_FILE ) or die "close: $!";
    }
    local $ENV{PERL_MM_USE_DEFAULT} = 1;
    local $ENV{AUTOMATED_TESTING}   = '';
    local $ENV{RELEASE_TESTING}     = '';
    $self->_run3( $self->bin_perl, $cpan_file ) or die "perl failed";
    die "Failure detected during cpan upgrade, stopping" if $?;

    my $fl = Perl::Dist::WiX::Filelist->new->readdir(
        catdir( $self->image_dir, 'perl' ) );

    $fl->subtract( $fl2 )->filter( $self->filters );

    $self->insert_fragment( 'upgraded_modules', $fl->files );

    return 1;
} ## end sub install_cpan_upgrades

# No additional modules by default
sub install_perl_modules {
    my $self = shift;

    # Upgrade anything out of date,
    # but don't install anything extra.
    $self->install_cpan_upgrades;
    
    return 1;
}

# Portability support must be added after modules
sub install_portable {
    my $self = shift;

    # Install the regular parts of Portability
    $self->install_module( name => 'Portable', );

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
        share      => 'Perl-Dist portable.perl',
        install_to => 'portable.perl',
    );

    return 1;
} ## end sub install_portable

# Install links and launchers and so on
sub install_win32_extras {
    my $self = shift;

    File::Path::mkpath( catdir( $self->image_dir, 'win32' ) );

    $self->install_launcher(
        name => 'CPAN Client',
        bin  => 'cpan',
    );
    $self->install_website(
        name      => 'CPAN Search',
        url       => 'http://search.cpan.org/',
        icon_file => catfile(
            File::ShareDir::dist_dir( 'Perl-Dist-WiX' ), 'cpan.ico'
        ) );

    if ( $self->perl_version_human eq '5.8.8' ) {
        $self->install_website(
            name      => 'Perl 5.8.8 Documentation',
            url       => 'http://perldoc.perl.org/5.8.8/',
            icon_file => catfile(
                File::ShareDir::dist_dir( 'Perl-Dist-WiX' ),
                'perldoc.ico'
            ) );
    }
    if ( $self->perl_version_human eq '5.8.9' ) {
        $self->install_website(
            name      => 'Perl 5.8.9 Documentation',
            url       => 'http://perldoc.perl.org/5.8.9/',
            icon_file => catfile(
                File::ShareDir::dist_dir( 'Perl-Dist-WiX' ),
                'perldoc.ico'
            ) );
    }
    if ( $self->perl_version_human eq '5.10.0' ) {
        $self->install_website(
            name      => 'Perl 5.10.0 Documentation',
            url       => 'http://perldoc.perl.org/',
            icon_file => catfile(
                File::ShareDir::dist_dir( 'Perl-Dist-WiX' ),
                'perldoc.ico'
            ) );
    }
    $self->install_website(
        name      => 'Win32 Perl Wiki',
        url       => 'http://win32.perl.org/',
        icon_file => catfile(
            File::ShareDir::dist_dir( 'Perl-Dist-WiX' ), 'win32.ico'
        ) );

    return $self;
} ## end sub install_win32_extras

# Delete various stuff we won't be needing
sub remove_waste {
    my $self = shift;

    $self->trace_line( 1, "Removing waste\n" );
    $self->trace_line( 2,
        "  Removing doc, man, info and html documentation\n" );
    $self->remove_dir( qw{ perl man       } );
    $self->remove_dir( qw{ perl html      } );
    $self->remove_dir( qw{ c    man       } );
    $self->remove_dir( qw{ c    doc       } );
    $self->remove_dir( qw{ c    info      } );
    $self->remove_dir( qw{ c    contrib   } );
    $self->remove_dir( qw{ c    html      } );

    $self->trace_line( 2, "  Removing C examples, manifests\n" );
    $self->remove_dir( qw{ c    examples  } );
    $self->remove_dir( qw{ c    manifest  } );

    $self->trace_line( 2, "  Removing redundant license files\n" );
    $self->remove_file( qw{ c COPYING     } );
    $self->remove_file( qw{ c COPYING.LIB } );

    $self->trace_line( 2,
        "  Removing CPAN build directories and download caches\n" );
    $self->remove_dir( qw{ cpan sources  } );
    $self->remove_dir( qw{ cpan build    } );

    return 1;
} ## end sub remove_waste

sub remove_dir {
    my $self = shift;
    my $dir  = $self->dir( @_ );
    File::Remove::remove( \1, $dir ) if -e $dir;
    return 1;
}

sub remove_file {
    my $self = shift;
    my $file = $self->file( @_ );
    File::Remove::remove( \1, $file ) if -e $file;
    return 1;
}


#####################################################################
# Perl 5.8.8 Support

=head3 install_perl_* (* = 588, 589, or 5100)

    $self->install_perl_5100;

The C<install_perl_*> method provides a simplified way to install
Perl into the distribution.

It takes care of calling C<install_perl_*_bin> with the standard
params, and then calls C<install_perl_toolchain> to set up the
CPAN toolchain.

Returns true, or throws an exception on error.

=pod

=head3 install_perl_*_bin

  $self->install_perl_5100_bin(
      name       => 'perl',
      dist       => 'RGARCIA/perl-5.10.0.tar.gz',
      unpack_to  => 'perl',
      license    => {
          'perl-5.10.0/Readme'   => 'perl/Readme',
          'perl-5.10.0/Artistic' => 'perl/Artistic',
          'perl-5.10.0/Copying'  => 'perl/Copying',
      },
      install_to => 'perl',
  );

The C<install_perl_*_bin> method takes care of the detailed process
of building the Perl binary and installing it into the
distribution.

A short summary of the process would be that it downloads or otherwise
fetches the named package, unpacks it, copies out any license files from
the source code, then tweaks the Win32 makefile to point to the specific
build directory, and then runs make/make test/make install. It also
registers some environment variables for addition to the Inno Setup
script.

It is normally called directly by C<install_perl_*> rather than
directly from the API, but is documented for completeness.

It takes a number of parameters that are sufficiently detailed above.

Returns true (after 20 minutes or so) or throws an exception on
error.

=cut

sub install_perl_588 {
    my $self = shift;

    # Prefetch and predelegate the toolchain so that it
    # fails early if there's a problem
    $self->trace_line( 1, "Pregenerating toolchain...\n" );
    my $toolchain =
      Perl::Dist::Util::Toolchain->new(
        perl_version => $self->perl_version_literal, )
      or croak "Failed to resolve toolchain modules";
    $toolchain->delegate;

    if ( $toolchain->{errstr} ) {
        croak "Failed to generate toolchain distributions";
    }

    # Make the perl directory if it hasn't been made alreafy.
    $self->make_path( catdir( $self->image_dir, 'perl' ) );

    # Get base filelist.
    my $fl2 = Perl::Dist::WiX::Filelist->new->readdir(
        catdir( $self->image_dir, 'perl' ) );

    # Install the main perl distributions
    $self->install_perl_588_bin(
        name       => 'perl',
        url        => 'http://strawberryperl.com/package/perl-5.8.8.tar.gz',
        unpack_to  => 'perl',
        install_to => 'perl',
        patch      => [qw{
              lib/ExtUtils/Install.pm
              lib/ExtUtils/Installed.pm
              lib/ExtUtils/Packlist.pm
              lib/ExtUtils/t/Install.t
              lib/ExtUtils/t/Installed.t
              lib/ExtUtils/t/Installapi2.t
              lib/ExtUtils/t/Packlist.t
              lib/ExtUtils/t/basic.t
              lib/ExtUtils/t/can_write_dir.t
              lib/CPAN/Config.pm
              }
        ],
        license => {
            'perl-5.8.8/Readme'   => 'perl/Readme',
            'perl-5.8.8/Artistic' => 'perl/Artistic',
            'perl-5.8.8/Copying'  => 'perl/Copying',
        },
    );

    my $fl_lic = Perl::Dist::WiX::Filelist->new->readdir(
        catdir( $self->image_dir, 'licenses', 'perl' ) );
    $self->insert_fragment( 'perl_licenses', $fl_lic->files );

    my $fl = Perl::Dist::WiX::Filelist->new->readdir(
        catdir( $self->image_dir, 'perl' ) );

    $fl->subtract( $fl2 )->filter( $self->filters );

    $self->insert_fragment( 'perl', $fl->files );

    # Upgrade the toolchain modules
    $self->install_perl_toolchain( $toolchain );

    return 1;
} ## end sub install_perl_588

sub install_perl_588_bin {
    my $self = shift;
    my $perl = Perl::Dist::Asset::Perl->new(
        parent => $self,
        force  => $self->force,
        @_,
    );
    unless ( $self->bin_make ) {
        croak( "Cannot build Perl yet, no bin_make defined" );
    }
    $self->trace_line( 0, "Preparing " . $perl->name . "\n" );

    # Download the file
    my $tgz = $self->_mirror( $perl->url, $self->download_dir, );

    # Unpack to the build directory
    my $unpack_to = catdir( $self->build_dir, $perl->unpack_to );
    if ( -d $unpack_to ) {
        $self->trace_line( 2, "Removing previous $unpack_to\n" );
        File::Remove::remove( \1, $unpack_to );
    }
    my @files = $self->_extract( $tgz, $unpack_to );

    # Get the versioned name of the directory
    ( my $perlsrc = $tgz ) =~ s{\.tar\.gz\z|\.tgz\z}{};
    $perlsrc = File::Basename::basename( $perlsrc );

    # Pre-copy updated files over the top of the source
    my $patch = $perl->patch;
    if ( $patch ) {

        # Overwrite the appropriate files
        foreach my $file ( @$patch ) {
            $self->patch_file( "perl-5.8.8/$file" => $unpack_to );
        }
    }

    # Copy in licenses
    if ( ref $perl->license eq 'HASH' ) {
        my $license_dir = catdir( $self->image_dir, 'licenses' );
        $self->_extract_filemap( $tgz, $perl->license, $license_dir, 1 );
    }

    # Build win32 perl
  SCOPE: {
        my $wd = $self->_pushd( $unpack_to, $perlsrc, "win32" );

        # Prepare to patch
        my $image_dir = $self->image_dir;
        my $INST_TOP = catdir( $self->image_dir, $perl->install_to );
        my ( $INST_DRV ) = splitpath( $INST_TOP, 1 );

        $self->trace_line( 2, "Patching makefile.mk\n" );
        $self->patch_file(
            'perl-5.8.8/win32/makefile.mk' => $unpack_to,
            {
                dist     => $self,
                INST_DRV => $INST_DRV,
                INST_TOP => $INST_TOP,
            } );

        $self->trace_line( 1, "Building perl...\n" );
        $self->_make;

        unless ( $perl->force ) {
            $self->trace_line( 0, <<"EOF");
***********************************************************
* Perl 5.8.8 cannot be tested at this point.
* It fails in op\\magic.c, tests 26 and 27 at this point.
* However, when running "dmake test" within the directory
* $wd,
* it passes all tests for me.
* 
* You may wish to try running "dmake test" within that
* directory yourself in order to verify that the
* perl being built works.
*
* -- csjewell\@cpan.org
***********************************************************
EOF
        
#            local $ENV{PERL_SKIP_TTY_TEST} = 1;
#            $self->trace_line( 1, "Testing perl...\n" );
#            $self->_make( 'test' );
        }

        $self->trace_line( 1, "Installing perl...\n" );
        $self->_make( qw/install UNINST=1/ );
    } ## end SCOPE:

    # Should now have a perl to use
    $self->{bin_perl} = catfile( $self->image_dir, qw/perl bin perl.exe/ );
    unless ( -x $self->bin_perl ) {
        croak( "Can't execute " . $self->bin_perl );
    }

    # Add to the environment variables
    $self->add_env_path( 'perl', 'bin' );

    return 1;
} ## end sub install_perl_588_bin



#####################################################################
# Perl 5.8.9 Support

sub install_perl_589 {
    my $self = shift;

    # Prefetch and predelegate the toolchain so that it
    # fails early if there's a problem
    $self->trace_line( 1, "Pregenerating toolchain...\n" );
    my $toolchain =
      Perl::Dist::Util::Toolchain->new(
        perl_version => $self->perl_version_literal, )
      or croak "Failed to resolve toolchain modules";
    $toolchain->delegate;

    if ( $toolchain->{errstr} ) {
        croak "Failed to generate toolchain distributions";
    }

    # Make the perl directory if it hasn't been made alreafy.
    $self->make_path( catdir( $self->image_dir, 'perl' ) );

    my $fl2 = Perl::Dist::WiX::Filelist->new->readdir(
        catdir( $self->image_dir, 'perl' ) );

    # Install the main perl distributions
    $self->install_perl_589_bin(
        name       => 'perl',
        url        => 'http://strawberryperl.com/package/perl-5.8.9.tar.gz',
        unpack_to  => 'perl',
        install_to => 'perl',
        patch      => [qw{
              lib/CPAN/Config.pm
              }
        ],
        license => {
            'perl-5.8.9/Readme'   => 'perl/Readme',
            'perl-5.8.9/Artistic' => 'perl/Artistic',
            'perl-5.8.9/Copying'  => 'perl/Copying',
        },
    );

    my $fl_lic = Perl::Dist::WiX::Filelist->new->readdir(
        catdir( $self->image_dir, 'licenses', 'perl' ) );
    $self->insert_fragment( 'perl_licenses', $fl_lic->files );

    my $fl = Perl::Dist::WiX::Filelist->new->readdir(
        catdir( $self->image_dir, 'perl' ) );

    $fl->subtract( $fl2 )->filter( $self->filters );

    $self->insert_fragment( 'perl', $fl->files );

    # Upgrade the toolchain modules
    $self->install_perl_toolchain( $toolchain );

    return 1;
} ## end sub install_perl_589

sub install_perl_589_bin {
    my $self = shift;
    my $perl = Perl::Dist::Asset::Perl->new(
        parent => $self,
        force  => $self->force,
        @_,
    );
    unless ( $self->bin_make ) {
        croak( "Cannot build Perl yet, no bin_make defined" );
    }
    $self->trace_line( 0, "Preparing " . $perl->name . "\n" );

    # Download the file
    my $tgz = $self->_mirror( $perl->url, $self->download_dir, );

    # Unpack to the build directory
    my $unpack_to = catdir( $self->build_dir, $perl->unpack_to );
    if ( -d $unpack_to ) {
        $self->trace_line( 2, "Removing previous $unpack_to\n" );
        File::Remove::remove( \1, $unpack_to );
    }
    my @files = $self->_extract( $tgz, $unpack_to );

    # Get the versioned name of the directory
    ( my $perlsrc = $tgz ) =~ s{\.tar\.gz\z|\.tgz\z}{};
    $perlsrc = File::Basename::basename( $perlsrc );

    # Pre-copy updated files over the top of the source
    my $patch = $perl->patch;
    if ( $patch ) {

        # Overwrite the appropriate files
        foreach my $file ( @$patch ) {
            $self->patch_file( "perl-5.8.9/$file" => $unpack_to );
        }
    }

    # Copy in licenses
    if ( ref $perl->license eq 'HASH' ) {
        my $license_dir = catdir( $self->image_dir, 'licenses' );
        $self->_extract_filemap( $tgz, $perl->license, $license_dir, 1 );
    }

    # Build win32 perl
  SCOPE: {
        my $wd = $self->_pushd( $unpack_to, $perlsrc, "win32" );

        # Prepare to patch
        my $image_dir = $self->image_dir;
        my $INST_TOP = catdir( $self->image_dir, $perl->install_to );
        my ( $INST_DRV ) = splitpath( $INST_TOP, 1 );

        $self->trace_line( 2, "Patching makefile.mk\n" );
        $self->patch_file(
            'perl-5.8.9/win32/makefile.mk' => $unpack_to,
            {
                dist     => $self,
                INST_DRV => $INST_DRV,
                INST_TOP => $INST_TOP,
            } );

        $self->trace_line( 1, "Building perl...\n" );
        $self->_make;

        unless ( $perl->force ) {
            local $ENV{PERL_SKIP_TTY_TEST} = 1;
            $self->trace_line( 1, "Testing perl...\n" );
            $self->_make( 'test' );
        }

        $self->trace_line( 1, "Installing perl...\n" );
        $self->_make( qw/install UNINST=1/ );
    } ## end SCOPE:

    # Should now have a perl to use
    $self->{bin_perl} = catfile( $self->image_dir, qw/perl bin perl.exe/ );
    unless ( -x $self->bin_perl ) {
        croak( "Can't execute " . $self->bin_perl );
    }

    # Add to the environment variables
    $self->add_env_path( 'perl', 'bin' );

    return 1;
} ## end sub install_perl_589_bin



#####################################################################
# Perl 5.10.0 Support


sub install_perl_5100 {
    my $self = shift;

    # Prefetch and predelegate the toolchain so that it
    # fails early if there's a problem
    $self->trace_line( 1, "Pregenerating toolchain...\n" );
    my $toolchain =
      Perl::Dist::Util::Toolchain->new(
        perl_version => $self->perl_version_literal, )
      or die( "Failed to resolve toolchain modules" );
    $toolchain->delegate;

    if ( $toolchain->{errstr} ) {
        die( "Failed to generate toolchain distributions" );
    }

    # Make the perl directory if it hasn't been made alreafy.
    $self->make_path( catdir( $self->image_dir, 'perl' ) );

    my $fl2 = Perl::Dist::WiX::Filelist->new->readdir(
        catdir( $self->image_dir, 'perl' ) );

    # Install the main binary
    $self->install_perl_5100_bin(
        name      => 'perl',
        url       => 'http://strawberryperl.com/package/perl-5.10.0.tar.gz',
        unpack_to => 'perl',
        install_to => 'perl',
        patch      => [qw{
              lib/ExtUtils/Command.pm
              lib/CPAN/Config.pm
              }
        ],
        license => {
            'perl-5.10.0/Readme'   => 'perl/Readme',
            'perl-5.10.0/Artistic' => 'perl/Artistic',
            'perl-5.10.0/Copying'  => 'perl/Copying',
        },
    );

    my $fl_lic = Perl::Dist::WiX::Filelist->new->readdir(
        catdir( $self->image_dir, 'licenses', 'perl' ) );
    $self->insert_fragment( 'perl_licenses', $fl_lic->files );

    my $fl = Perl::Dist::WiX::Filelist->new->readdir(
        catdir( $self->image_dir, 'perl' ) );

    $fl->subtract( $fl2 )->filter( $self->filters );

    $self->insert_fragment( 'perl', $fl->files );

    # Install the toolchain
    $self->install_perl_toolchain( $toolchain );

    return 1;
} ## end sub install_perl_5100

sub install_perl_5100_bin {
    my $self = shift;
    my $perl = Perl::Dist::Asset::Perl->new(
        parent => $self,
        force  => $self->force,
        @_,
    );
    unless ( $self->bin_make ) {
        croak "Cannot build Perl yet, no bin_make defined";
    }
    $self->trace_line( 0, "Preparing " . $perl->name . "\n" );

    # Download the file
    my $tgz = $self->_mirror( $perl->url, $self->download_dir, );

    # Unpack to the build directory
    my $unpack_to = catdir( $self->build_dir, $perl->unpack_to );
    if ( -d $unpack_to ) {
        $self->trace_line( 2, "Removing previous $unpack_to\n" );
        File::Remove::remove( \1, $unpack_to );
    }
    $self->_extract( $tgz, $unpack_to );

    # Get the versioned name of the directory
    ( my $perlsrc = $tgz ) =~ s{\.tar\.gz\z|\.tgz\z}{};
    $perlsrc = File::Basename::basename( $perlsrc );

    # Pre-copy updated files over the top of the source
    my $patch = $perl->patch;
    if ( $patch ) {

        # Overwrite the appropriate files
        foreach my $file ( @$patch ) {
            $self->patch_file( "perl-5.10.0/$file" => $unpack_to );
        }
    }

    # Copy in licenses
    if ( ref $perl->license eq 'HASH' ) {
        my $license_dir = catdir( $self->image_dir, 'licenses' );
        $self->_extract_filemap( $tgz, $perl->license, $license_dir, 1 );
    }

    # Build win32 perl
  SCOPE: {
        my $wd = $self->_pushd( $unpack_to, $perlsrc, "win32" );

        # Prepare to patch
        my $image_dir = $self->image_dir;
        my $INST_TOP = catdir( $self->image_dir, $perl->install_to );
        my ( $INST_DRV ) = splitpath( $INST_TOP, 1 );

        $self->trace_line( 2, "Patching makefile.mk\n" );
        $self->patch_file(
            'perl-5.10.0/win32/makefile.mk' => $unpack_to,
            {
                dist     => $self,
                INST_DRV => $INST_DRV,
                INST_TOP => $INST_TOP,
            } );

        $self->trace_line( 1, "Building perl...\n" );
        $self->_make;

        unless ( $perl->force ) {
            local $ENV{PERL_SKIP_TTY_TEST} = 1;
            $self->trace_line( 1, "Testing perl...\n" );
            $self->_make( 'test' );
        }

        $self->trace_line( 1, "Installing perl...\n" );
        $self->_make( 'install' );
    } ## end SCOPE:

    # Should now have a perl to use
    $self->{bin_perl} = catfile( $self->image_dir, qw/perl bin perl.exe/ );
    unless ( -x $self->bin_perl ) {
        die "Can't execute " . $self->bin_perl;
    }

    # Add to the environment variables
    $self->add_env_path( 'perl', 'bin' );

    return 1;
} ## end sub install_perl_5100_bin



#####################################################################
# Installing C Toolchain and Library Packages

=pod

=head3 install_dmake

  $dist->install_dmake

The C<install_dmake> method installs the B<dmake> make tool into the
distribution, and is typically installed during "C toolchain" build
phase.

It provides the approproate arguments to C<install_binary> and then
validates that the binary was installed correctly.

Returns true or throws an exception on error.

=cut

sub install_dmake {
    my $self = shift;

    # Install dmake
    my $filelist = $self->install_binary(
        name    => 'dmake',
        license => {
            'dmake/COPYING'            => 'dmake/COPYING',
            'dmake/readme/license.txt' => 'dmake/license.txt',
        },
        install_to => {
            'dmake/dmake.exe' => 'c/bin/dmake.exe',
            'dmake/startup'   => 'c/bin/startup',
        },
    );

    # Initialize the make location
    $self->{bin_make} =
      catfile( $self->image_dir, 'c', 'bin', 'dmake.exe' );
    unless ( -x $self->bin_make ) {
        croak( "Can't execute make" );
    }

    $self->insert_fragment( 'dmake', $filelist->files );

    return 1;
} ## end sub install_dmake

=pod

=head3 install_gcc

  $dist->install_gcc

The C<install_gcc> method installs the B<GNU C Compiler> into the
distribution, and is typically installed during "C toolchain" build
phase.

It provides the appropriate arguments to several C<install_binary>
calls. The default C<install_gcc> method installs two binary
packages, the core compiler 'gcc-core' and the C++ compiler 'gcc-c++'.

Returns true or throws an exception on error.

=cut

sub install_gcc {
    my $self = shift;

    # Install the compilers (gcc)
    my $fl = $self->install_binary(
        name    => 'gcc-core',
        license => {
            'COPYING'     => 'gcc/COPYING',
            'COPYING.lib' => 'gcc/COPYING.lib',
        },
    );

    $self->insert_fragment( 'gcc_core', $fl->files );

    $fl = $self->install_binary( name => 'gcc-g++', );

    $self->insert_fragment( 'gcc_gplusplus', $fl->files );

    return 1;
} ## end sub install_gcc

=pod

=head3 install_binutils

  $dist->install_binutils

The C<install_binutils> method installs the C<GNU binutils> package into
the distribution.

The most important of these is C<dlltool.exe>, which is used to extract
static library files from .dll files. This is needed by some libraries
to let the Perl interfaces build against them correctly.

Returns true or throws an exception on error.

=cut

sub install_binutils {
    my $self = shift;

    my $filelist = $self->install_binary(
        name    => 'binutils',
        license => {
            'Copying'     => 'binutils/Copying',
            'Copying.lib' => 'binutils/Copying.lib',
        },
    );
    $self->{bin_dlltool} =
      catfile( $self->image_dir, 'c', 'bin', 'dlltool.exe' );
    unless ( -x $self->bin_dlltool ) {
        die "Can't execute dlltool";
    }

    $self->insert_fragment( 'binutils', $filelist->files );

    return 1;
} ## end sub install_binutils

=pod

=head3 install_pexports

  $dist->install_pexports

The C<install_pexports> method installs the C<MinGW pexports> package
into the distribution.

This is needed by some libraries to let the Perl interfaces build against
them correctly.

Returns true or throws an exception on error.

=cut

sub install_pexports {
    my $self = shift;

    my $filelist = $self->install_binary(
        name       => 'pexports',
        url        => $self->binary_url( 'pexports-0.43-1.zip' ),
        license    => { 'pexports-0.43/COPYING' => 'pexports/COPYING', },
        install_to => { 'pexports-0.43/bin' => 'c/bin', },
    );
    $self->{bin_pexports} =
      catfile( $self->image_dir, 'c', 'bin', 'pexports.exe' );
    unless ( -x $self->bin_pexports ) {
        die "Can't execute pexports";
    }

    $self->insert_fragment( 'pexports', $filelist->files );

    return 1;
} ## end sub install_pexports

=pod

=head3 install_mingw_runtime

  $dist->install_mingw_runtime

The C<install_mingw_runtime> method installs the MinGW runtime package
into the distribution, which is basically the MinGW version of libc and
some other very low level libs.

Returns true or throws an exception on error.

=cut

sub install_mingw_runtime {
    my $self = shift;

    my $filelist = $self->install_binary(
        name    => 'mingw-runtime',
        license => {
            'doc/mingw-runtime/Contributors' => 'mingw/Contributors',
            'doc/mingw-runtime/Disclaimer'   => 'mingw/Disclaimer',
        },
    );

    $self->insert_fragment( 'mingw_runtime', $filelist->files );

    return 1;
} ## end sub install_mingw_runtime

=pod

=head3 install_zlib

  $dist->install_zlib

The C<install_zlib> method installs the B<GNU zlib> compression library
into the distribution, and is typically installed during "C toolchain"
build phase.

It provides the appropriate arguments to a C<install_library> call that
will extract the standard zlib win32 package, and generate the additional
files that Perl needs.

Returns true or throws an exception on error.

=cut

sub install_zlib {
    my $self = shift;

    # Zlib is a pexport-based lib-install
    my $filelist = $self->install_library(
        name      => 'zlib',
        url       => $self->binary_url( 'zlib-1.2.3.win32.zip' ),
        unpack_to => 'zlib',
        build_a   => {
            'dll' => 'zlib-1.2.3.win32/bin/zlib1.dll',
            'def' => 'zlib-1.2.3.win32/bin/zlib1.def',
            'a'   => 'zlib-1.2.3.win32/lib/zlib1.a',
        },
        install_to => {
            'zlib-1.2.3.win32/bin'     => 'c/bin',
            'zlib-1.2.3.win32/lib'     => 'c/lib',
            'zlib-1.2.3.win32/include' => 'c/include',
        },
    );

    $self->insert_fragment( 'zlib', $filelist->files );

    return 1;
} ## end sub install_zlib

=pod

=head3 install_win32api

  $dist->install_win32api

The C<install_win32api> method installs C<MinGW win32api> layer, to
allow C code to compile against native Win32 APIs.

Returns true or throws an exception on error.

=cut

sub install_win32api {
    my $self = shift;

    my $filelist = $self->install_binary( name => 'w32api', );

    $self->insert_fragment( 'w32api', $filelist->files );

    return 1;
}

=pod

=head3 install_mingw_make

  $dist->install_mingw_make

The C<install_mingw_make> method installs the MinGW build of the B<GNU make>
build tool.

While GNU make is not used by Perl itself, some C libraries can't be built
using the normal C<dmake> tool and explicitly need GNU make. So we install
it as mingw-make and certain Alien:: modules will use it by that name.

Returns true or throws an exception on error.

=cut

sub install_mingw_make {
    my $self = shift;

    my $filelist = $self->install_binary( name => 'mingw-make', );

    $self->insert_fragment( 'mingw_make', $filelist->files );

    return 1;
}

=pod

=head3 install_libiconv

  $dist->install_libiconv

The C<install_libiconv> method installs the C<GNU libiconv> library,
which is used for various character encoding tasks, and is needed for
other libraries such as C<libxml>.

Returns true or throws an exception on error.

=cut

sub install_libiconv {
    my $self     = shift;
    my $filelist = Perl::Dist::WiX::Filelist->new;
    my $fl;

    # libiconv for win32 comes in 3 parts, install them.
    $fl = $self->install_binary( name => 'libiconv-dep', );
    $filelist->add( $fl );
    $fl = $self->install_binary( name => 'libiconv-lib', );
    $filelist->add( $fl );
    $fl = $self->install_binary( name => 'libiconv-bin', );
    $filelist->add( $fl );

    # The dll is installed with an unexpected name,
    # so we correct it post-install.
    my $from = catfile( $self->image_dir, 'c', 'bin', 'libiconv2.dll' );
    my $to   = catfile( $self->image_dir, 'c', 'bin', 'iconv.dll' );
    $self->_move( $from, $to );
    $filelist->move( $from, $to );

    $self->insert_fragment( 'libiconv', $filelist->files );

    return 1;
} ## end sub install_libiconv

=pod

=head3 install_libxml

  $dist->install_libxml

The C<install_libxml> method installs the C<Gnome libxml> library,
which is a fast, reliable, XML parsing library, and the new standard
library for XML parsing.

Returns true or throws an exception on error.

=cut

sub install_libxml {
    my $self = shift;

    # libxml is a straight forward pexport-based install
    my $filelist = $self->install_library(
        name      => 'libxml2',
        url       => $self->binary_url( 'libxml2-2.6.30.win32.zip' ),
        unpack_to => 'libxml2',
        build_a   => {
            'dll' => 'libxml2-2.6.30.win32/bin/libxml2.dll',
            'def' => 'libxml2-2.6.30.win32/bin/libxml2.def',
            'a'   => 'libxml2-2.6.30.win32/lib/libxml2.a',
        },
        install_to => {
            'libxml2-2.6.30.win32/bin'     => 'c/bin',
            'libxml2-2.6.30.win32/lib'     => 'c/lib',
            'libxml2-2.6.30.win32/include' => 'c/include',
        },
    );

    $self->insert_fragment( 'libxml', $filelist->files );

    return 1;
} ## end sub install_libxml

=pod

=head3 install_expat

  $dist->install_expat

The C<install_expat> method installs the C<Expat> XML library,
which was the first popular C XML parser. Many Perl XML libraries
are based on Expat.

Returns true or throws an exception on error.

=cut

sub install_expat {
    my $self = shift;

    # Install the PAR version of libexpat
    my $filelist = $self->install_par(
        name         => 'libexpat',
        share        => 'Perl-Dist vanilla/libexpat-vanilla.par',
        install_perl => 1,
        install_c    => 0,
    );

    $self->insert_fragment( 'libexpat', $filelist->files );

    return 1;
} ## end sub install_expat

=pod

=head3 install_gmp

  $dist->install_gmp

The C<install_gmp> method installs the C<GNU Multiple Precision Arithmetic
Library>, which is used for fast and robust bignum support.

Returns true or throws an exception on error.

=cut

sub install_gmp {
    my $self = shift;

    # Comes as a single prepackaged vanilla-specific zip file
    my $filelist = $self->install_binary( name => 'gmp', );

    $self->insert_fragment( 'gmp', $filelist->files );

    return 1;
}

=pod

=head3 install_pari

  $dist->install_pari

The C<install_pari> method install (via a PAR package) libpari and the
L<Math::Pari> module into the distribution.

This method should only be called at during the install_modules phase.

=cut

sub install_pari {
    my $self = shift;

    my $filelist = $self->install_par(
        name => 'pari',
        url  => 'http://strawberryperl.com/package/Math-Pari-2.010800.par',
    );

    $self->insert_fragment( 'pari', $filelist->files );

    return 1;
} ## end sub install_pari



#####################################################################
# General Installation Methods

=pod

=head2 General installation methods

=head3 install_binary

  $self->install_binary(
      name => 'gmp',
  );

The C<install_binary> method is used by library-specific methods to
install pre-compiled and un-modified tar.gz or zip archives into
the distribution.

Returns true or throws an exception on error.

=cut

sub install_binary {
    my $self   = shift;
    my $binary = Perl::Dist::Asset::Binary->new(
        parent     => $self,
        install_to => 'c',             # Default to the C dir
        @_,
    );
    my $name = $binary->name;
    $self->trace_line( 1, "Preparing $name\n" );

    # Download the file
    my $tgz = $self->_mirror( $binary->url, $self->download_dir, );

    # Unpack the archive
    my @files;
    my $install_to = $binary->install_to;
    if ( ref $binary->install_to eq 'HASH' ) {
        @files =
          $self->_extract_filemap( $tgz, $binary->install_to,
            $self->image_dir );

    } elsif ( !ref $binary->install_to ) {

        # unpack as a whole
        my $tgt = catdir( $self->image_dir, $binary->install_to );
        @files = $self->_extract( $tgz, $tgt );
    } else {
        die "didn't expect install_to to be a " . ref $binary->install_to;
    }

    # Find the licenses
    if ( ref $binary->license eq 'HASH' ) {
        push @files,
          $self->_extract_filemap( $tgz, $binary->license,
            $self->license_dir, 1 );
    }

    my $filelist =
      Perl::Dist::WiX::Filelist->new->load_array( @files )
      ->filter( $self->filters );

    return $filelist;
} ## end sub install_binary

=head3 install_library

  $self->install_binary(
      name => 'gmp',
  );

The C<install_binary> method is used by library-specific methods to
install pre-compiled and un-modified tar.gz or zip archives into
the distribution.

Returns true or throws an exception on error.

=cut


sub install_library {
    my $self    = shift;
    my $library = Perl::Dist::Asset::Library->new(
        parent => $self,
        @_,
    );
    my $name = $library->name;
    $self->trace_line( 1, "Preparing $name\n" );

    # Download the file
    my $tgz = $self->_mirror( $library->url, $self->download_dir, );

    # Unpack to the build directory
    my @files;
    my $unpack_to = catdir( $self->build_dir, $library->unpack_to );
    if ( -d $unpack_to ) {
        $self->trace_line( 2, "Removing previous $unpack_to\n" );
        File::Remove::remove( \1, $unpack_to );
    }
    @files = $self->_extract( $tgz, $unpack_to );

    # Build the .a file if needed
    if ( _HASH( $library->build_a ) ) {

        # Hand off for the .a generation
        push @files,
          $self->_dll_to_a(
            $library->build_a->{source}
            ? ( source =>
                  catfile( $unpack_to, $library->build_a->{source} ), )
            : (),
            dll => catfile( $unpack_to, $library->build_a->{dll} ),
            def => catfile( $unpack_to, $library->build_a->{def} ),
            a   => catfile( $unpack_to, $library->build_a->{a} ),
          );
    } ## end if ( _HASH( $library->build_a...

    # Copy in the files
    my $install_to = $library->install_to;
    if ( _HASH( $install_to ) ) {
        foreach my $k ( sort keys %$install_to ) {
            my $from = catdir( $unpack_to,       $k );
            my $to   = catdir( $self->image_dir, $install_to->{$k} );
            $self->_copy( $from, $to );
            @files = $self->_copy_filesref( \@files, $from, $to );
        }
    }

    # Copy in licenses
    if ( _HASH( $library->license ) ) {
        my $license_dir = catdir( $self->image_dir, 'licenses' );
        push @files,
          $self->_extract_filemap( $tgz, $library->license, $license_dir,
            1 );
    }

    my @sorted_files = sort { $a cmp $b } @files;
    my $filelist =
      Perl::Dist::WiX::Filelist->new->load_array( @sorted_files )
      ->filter( $self->filters );

    return $filelist;
} ## end sub install_library

sub _copy_filesref {
    my ( $self, $files_ref, $from, $to ) = @_;

    my @files;

    foreach my $file ( @{$files_ref} ) {
        if ( $file =~ m{\A\Q$from\E} ) {
            $file =~ s{\A\Q$from\E}{$to};
        }
        push @files, $file;
    }

    return @files;
} ## end sub _copy_filesref

=pod

=head3 install_distribution

  $self->install_distribution(
      name              => 'ADAMK/File-HomeDir-0.69.tar.gz,
      force             => 1,
      automated_testing => 1,
      makefilepl_param  => [
          'LIBDIR=' . File::Spec->catdir(
              $self->image_dir, 'c', 'lib',
          ),
      ],
  );

The C<install_distribution> method is used to install a single
CPAN or non-CPAN distribution directly, without installing any of the
dependencies for that distribution.

It is used primarily during CPAN bootstrapping, to allow the
installation of the toolchain modules, with the distribution install
order precomputed or hard-coded.

It takes a compulsory 'name' param, which should be the AUTHOR/file
path within the CPAN mirror.

The optional 'force' param allows the installation of distributions
with spuriously failing test suites.

The optional 'automated_testing' param allows for installation
with the C<AUTOMATED_TESTING> environment flag enabled, which is
used to either run more-intensive testing, or to convince certain
Makefile.PL that insists on prompting that there is no human around
and they REALLY need to just go with the default options.

The optional 'makefilepl_param' param should be a reference to an
array of additional params that should be passwd to the
C<perl Makefile.PL>. This can help with distributions that insist
on taking additional options via Makefile.PL.

Returns true or throws an exception on error.

=cut

sub install_distribution {
    my $self = shift;
    my $dist = Perl::Dist::Asset::Distribution->new(
        parent => $self,
        force  => $self->force,
        @_,
    );
    my $name = $dist->name;

# If we don't have a packlist file, get an initial filelist to subtract from.
    my $module  = $self->_name_to_module( $name );
    my $fl_flag = $self->_need_packlist( $module );
    my $filelist_sub;

    if ( not $fl_flag ) {
        $filelist_sub = Perl::Dist::WiX::Filelist->new->readdir(
            catdir( $self->image_dir, 'perl' ) );
    }

    # Download the file
    my $tgz =
      $self->_mirror( $dist->abs_uri( $self->cpan ), $self->modules_dir, );

    # Where will it get extracted to
    my $dist_path = $name;
    $dist_path =~ s/\.tar\.gz//;
    $dist_path =~ s/\.zip//;
    $dist_path =~ s/.+\///;
    my $unpack_to = catdir( $self->build_dir, $dist_path );

    # Extract the tarball
    if ( -d $unpack_to ) {
        $self->trace_line( 2, "Removing previous $unpack_to\n" );
        File::Remove::remove( \1, $unpack_to );
    }
    $self->_extract( $tgz => $self->build_dir );
    unless ( -d $unpack_to ) {
        croak( "Failed to extract $unpack_to" );
    }

    # Build the module
  SCOPE: {
        my $wd = $self->_pushd( $unpack_to );

        # Enable automated_testing mode if needed
        # Blame Term::ReadLine::Perl for needing this ugly hack.
        if ( $dist->automated_testing ) {
            $self->trace_line( 2,
                "Installing with AUTOMATED_TESTING enabled...\n" );
        }
        if ( $dist->release_testing ) {
            $self->trace_line( 2,
                "Installing with RELEASE_TESTING enabled...\n" );
        }
        local $ENV{AUTOMATED_TESTING} = $dist->automated_testing;
        local $ENV{RELEASE_TESTING}   = $dist->release_testing;

        $self->trace_line( 2, "Configuring $name...\n" );
        $self->_perl( 'Makefile.PL', @{ $dist->makefilepl_param } );

        $self->trace_line( 1, "Building $name...\n" );
        $self->_make;

        unless ( $dist->force ) {
            $self->trace_line( 2, "Testing $name...\n" );
            $self->_make( 'test' );
        }

        $self->trace_line( 2, "Installing $name...\n" );
        $self->_make( qw/install UNINST=1/ );
    } ## end SCOPE:

    # Making final filelist.
    my $filelist;
    if ( $fl_flag ) {
        $filelist = $self->search_packlist( $module );
    } else {
        $filelist = Perl::Dist::WiX::Filelist->new->readdir(
            catdir( $self->image_dir, 'perl' ) );
        $filelist->subtract( $filelist_sub )->filter( $self->filters );
    }
    my $mod_id = $module;
    $mod_id =~ s/::/_/g;

    # Insert fragment.
    $self->insert_fragment( $mod_id, $filelist->files );

    return $self;
} ## end sub install_distribution

sub _name_to_module {
    my ( $self, $dist ) = @_;

#<<<
    my ( $module ) = $dist =~ m{\A  # Start the string...
                    [A-Za-z/]*      # With a string of letters and slashes
                    /               # followed by a forward slash. 
                    (.*?)           # Then capture all characters, non-greedily 
                    -\d*[.]         # up to a dash, a sequence of digits, and then a period.
                    }smx;           # (i.e. starting a version number.
#>>>
    $module =~ s{-}{::}g;

    return $module;
} ## end sub _name_to_module

sub search_packlists {
    my $self = shift;
    my ( $packlist, $mod_id );

    foreach my $name ( @_ ) {
        $packlist = $self->search_packlist( $name );
        $mod_id   = $name;
        $mod_id =~ s/::/_/g;
        $self->insert_fragment( $mod_id, $packlist->files );
    }

    return $self;
} ## end sub search_packlists

sub search_packlist {
    my ( $self, $module ) = @_;

    my $perl = catfile(
        catdir(
            $self->image_dir,
            qw{perl      lib auto},
            split( '::', $module )
        ),
        '.packlist'
    );
    my $site = catfile(
        catdir(
            $self->image_dir,
            qw{perl site lib auto},
            split( '::', $module )
        ),
        '.packlist'
    );
    my $fl;

    if ( -r $perl ) {
        $fl =
          Perl::Dist::WiX::Filelist->new->load_file( $perl )
          ->add_file( $perl );
    } elsif ( -r $site ) {
        $fl =
          Perl::Dist::WiX::Filelist->new->load_file( $site )
          ->add_file( $site );
    } else {
        croak "No .packlist found for $module";
    }

    return $fl->filter( $self->filters );
} ## end sub search_packlist

sub _need_packlist {
    my ( $self, $module ) = @_;

    my @mods = qw(
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
      IO::Compress::Base
      Compress::Raw::Zlib
      Compress::Raw::Bzip2
      IO::Compress::Zlib
      IO::Compress::Bzip2
      Compress::Zlib
      Compress::Bzip2
      IO::Zlib
      File::Temp
      Win32API::Registry
      Win32::TieRegistry
      File::HomeDir
      File::Which
      Archive::Zip
      IO::String
      YAML
      Digest::SHA1
      Digest::SHA
      Module::Build
      CPAN
      Text::Glob
      HTML::Tagset
      HTML::Parser
      CPAN::SQLite
      DBD::SQLite
      DBI
      pler
      pip
      PPM
      PAR::Repository::Client
      DBM::Deep
      PAR::Dist::InstallPPD
      Test::Exception
      Test::Warn
      Test::Deep
      XML::LibXML
      XML::Parser
      Math::BigInt
      Math::BigInt::FastCalc
      Math::BigRat
      Math::BigInt::GMP
      Win32::File
      Win32::File::Object
      Win32::API
      Win32::Env::Path
      Win32::Exe
      LWP::Online
      Pod::Simple
      Time::Piece
    );

    return any { $module eq $_ } @mods;
} ## end sub _need_packlist

=pod

=head3 install_module

  $self->install_module(
      name => 'DBI',
  );

The C<install_module> method is a high level installation method that can
be used during the C<install_perl_modules> phase, once the CPAN toolchain
has been been initialized.

It makes the installation call using the CPAN client directly, allowing
the CPAN client to both do the installation and fulfill all of the
dependencies for the module, identically to if it was installed from
the CPAN shell via an "install Module::Name" command.

The compulsory 'name' param should be the class name of the module to
be installed.

The optional 'force' param can be used to force the install of module.
This does not, however, force the installation of the dependencies of
the module.

Returns true or throws an exception on error.

=cut

sub install_module {
    my $self   = shift;
    my $module = Perl::Dist::Asset::Module->new(
        force  => $self->force,
        parent => $self,
        @_,
    );
    my $name  = $module->name;
    my $force = $module->force;

    unless ( $self->bin_perl ) {
        croak( "Cannot install CPAN modules yet, perl is not installed" );
    }
    my $dist_file = catfile( $self->build_dir, 'cpan_distro.txt' );

    # Generate the CPAN installation script
    my $cpan_string = <<"END_PERL";
print "Loading CPAN...\\n";
use CPAN;
CPAN::HandleConfig->load unless \$CPAN::Config_loaded++;
print "Installing $name from CPAN...\\n";
my \$module = CPAN::Shell->expandany( "$name" ) 
	or die "CPAN.pm couldn't locate $name";
if ( \$module->uptodate ) {
	print "$name is up to date\\n";
	exit(0);
}
SCOPE: {
    my \$dist_file = '$dist_file'; 
    open( CPAN_FILE, '>', \$dist_file )      or die "open: $!";
    print CPAN_FILE 
        \$module->distribution()->pretty_id() or die "print: $!";
    close( CPAN_FILE )                       or die "close: $!";
}

print "\\\$ENV{PATH} = '\$ENV{PATH}'\\n";
if ( $force ) {
	CPAN::Shell->notest('install', '$name');
} else {
	CPAN::Shell->install('$name');
}
print "Completed install of $name\\n";
unless ( \$module->uptodate ) {
	die "Installation of $name appears to have failed";
}
exit(0);
END_PERL

    my $fl_flag = $self->_need_packlist( $module->name );
    my $filelist_sub;
    if ( not $fl_flag ) {
        $filelist_sub = Perl::Dist::WiX::Filelist->new->readdir(
            catdir( $self->image_dir, 'perl' ) );
    }

    # Dump the CPAN script to a temp file and execute
    $self->trace_line( 1, "Running install of $name\n" );
    my $cpan_file = catfile( $self->build_dir, 'cpan_string.pl' );
  SCOPE: {
        open( CPAN_FILE, '>', $cpan_file ) or die "open: $!";
        print CPAN_FILE $cpan_string or die "print: $!";
        close( CPAN_FILE ) or die "close: $!";
    }
    local $ENV{PERL_MM_USE_DEFAULT} = 1;
    local $ENV{AUTOMATED_TESTING}   = '';
    local $ENV{RELEASE_TESTING}     = '';
    $self->_run3( $self->bin_perl, $cpan_file ) or croak "perl failed";
    croak "Failure detected installing $name, stopping [$?]" if $?;


    # Read in the dist file and return it as $dist_info.
    my @files;
    my $fh = IO::File->new( $dist_file, 'r' );
    if ( not defined $fh ) {
        croak "File Error: $!";
    }
    my $dist_info = <$fh>;
    $fh->close;

    # Making final filelist.
    my $filelist;
    if ( $fl_flag ) {
        $filelist = $self->search_packlist( $module->name );
    } else {
        $filelist = Perl::Dist::WiX::Filelist->new->readdir(
            catdir( $self->image_dir, 'perl' ) );
        $filelist->subtract( $filelist_sub )->filter( $self->filters );
    }
    my $mod_id = $module->name;
    $mod_id =~ s/::/_/g;

    # Insert fragment.
    $self->insert_fragment( $mod_id, $filelist->files )
      unless ( 0 == scalar @{ $filelist->files } );

    return $self;
} ## end sub install_module

=pod

=head3 install_modules

  $self->install_modules( qw{
      Foo::Bar
      This::That
      One::Two
  } );

The C<install_modules> method is a convenience shorthand that makes it
trivial to install a series of modules via C<install_module>.

As a convenience, it does not support any additional params to the
underlying C<install_module> call other than the name.

=cut

sub install_modules {
    my $self = shift;

    foreach my $name ( @_ ) {
        $self->install_module( name => $name );
    }

    return $self;
}

=pod

=head3 install_par

The C<install_par> method extends the available installation options to
allow for the install of pre-compiled modules and pre-compiled C libraries
via "PAR" packages.

The compulsory 'name' param should be a simple identifying name, and does
not have any functional use.

The compulsory 'uri' param should be a URL string to the PAR package.

Returns true on success or throws an exception on error.

=cut

sub install_par {
    my $self = shift;
    my $output;
    $self->trace_line( 1, "Preparing " . {@_}->{name} . "\n" );
    my $io = IO::String->new( $output );
    my $packlist;

    {                                  # When $saved goes out of context, STDOUT will be restored.
        my $saved = SelectSaver->new( $io );

        # Create Asset::Par object.
        my $par = Perl::Dist::Asset::PAR->new(
            parent => $self,

            # not supported at the moment:
            #install_to => 'c', # Default to the C dir
            @_,
        );

        # Download the file.
        # Do it here for consistency instead of letting PAR::Dist do it
        my $file = $self->_mirror( $par->url, $self->download_dir, );

        # Set the appropriate installation paths
        my $no_colon = $par->name;
        $no_colon =~ s/::/-/g;
        my $perldir = catdir( $self->image_dir, 'perl' );
        my $libdir = catdir( $perldir, 'site', 'lib' );
        my $bindir = catdir( $perldir, 'bin' );
        $packlist = catfile( $libdir, $no_colon, '.packlist' );
        my $cdir = catdir( $self->image_dir, 'c' );

        # Suppress warnings for resources that don't exist
        local $^W = 0;

        # Install
        PAR::Dist::install_par(
            dist           => $file,
            packlist_read  => $packlist,
            packlist_write => $packlist,
            inst_lib       => $libdir,
            inst_archlib   => $libdir,
            inst_bin       => $bindir,
            inst_script    => $bindir,
            inst_man1dir   => undef,   # no man pages
            inst_man3dir   => undef,   # no man pages
            custom_targets => {
                'blib/c/lib'     => catdir( $cdir, 'lib' ),
                'blib/c/bin'     => catdir( $cdir, 'bin' ),
                'blib/c/include' => catdir( $cdir, 'include' ),
                'blib/c/share'   => catdir( $cdir, 'share' ),
            },
        );
    }

    # Print saved output if required.
    $io->close;
    $self->trace_line( 2, $output );

    # Read in the .packlist and return it.
    my $filelist =
      Perl::Dist::WiX::Filelist->new->load_file( $packlist )
      ->filter( $self->filters )->add_file( $packlist );

    return $filelist;
} ## end sub install_par

=pod

=head3 install_file

  # Overwrite the CPAN::Config
  $self->install_file(
      share      => 'Perl-Dist CPAN_Config.pm',
      install_to => 'perl/lib/CPAN/Config.pm',
  );
  
  # Install a custom icon file
  $self->install_file(
      name       => 'Strawberry Perl Website Icon',
      url        => 'http://strawberryperl.com/favicon.ico',
      install_to => 'Strawberry Perl Website.ico',
  );

The C<install_file> method is used to install a single specific file from
various sources into the distribution.

It is generally used to overwrite modules with distribution-specific
customisations, or to install licenses, README files, or other
miscellaneous data files which don't need to be compiled or modified.

It takes a variety of different params.

The optional 'name' param provides an optional plain name for the file.
It does not have any functional purpose or meaning for this method.

One of several alternative source methods must be provided.

The 'url' method is used to provide a fully-resolved path to the
source file and should be a fully-resolved URL.

The 'file' method is used to provide a local path to the source file
on the local system, and should be a fully-resolved filesystem path.

The 'share' method is used to provide a path to a file installed as
part of a CPAN distribution, and accessed via L<File::ShareDir>.

It should be a string containing two space-seperated value, the first
of which is the distribution name, and the second is the path within
the share dir of that distribution.

The final compulsory method is the 'install_to' method, which provides
either a destination file path, or alternatively a path to an existing
directory that the file be installed below, using its source file name.

Returns true or throws an exception on error.

=cut

sub install_file {
    my $self = shift;
    my $dist = Perl::Dist::Asset::File->new(
        parent => $self,
        @_,
    );

    my @files;

    # Get the file
    my $tgz = $self->_mirror( $dist->url, $self->download_dir );

    # Copy the file to the target location
    my $from = catfile( $self->download_dir, $dist->file );
    my $to   = catfile( $self->image_dir,    $dist->install_to );
    unless ( -f $to ) {
        push @files, $to;
    }

    $self->_copy( $from => $to );

    # Clear the download file
    File::Remove::remove( \1, $tgz );

    my $filelist =
      Perl::Dist::WiX::Filelist->new->load_array( @files )
      ->filter( $self->filters );

    return $filelist;
} ## end sub install_file

=pod

=head3 install_launcher

  $self->install_launcher(
      name => 'CPAN Client',
      bin  => 'cpan',
  );

The C<install_launcher> method is used to describe a binary program
launcher that will be added to the Windows "Start" menu when the
distribution is installed.

It takes two compulsory param.

The compulsory 'name' param is the name of the launcher, and the text
that label will be displayed in the start menu (Currently this only
supports ASCII, and is not language-aware in any way).

The compulsory 'bin' param should be the name of a .bat script launcher
in the Perl bin directory. The program itself MUST be installed before
trying to add the launcher.

Returns true or throws an exception on error.

=cut

sub install_launcher {
    my $self     = shift;
    my $launcher = Perl::Dist::Asset::Launcher->new(
        parent => $self,
        @_,
    );

    # Check the script exists
    my $to =
      catfile( $self->image_dir, 'perl', 'bin', $launcher->bin . '.bat' );
    unless ( -f $to ) {
        die "The script '" . $launcher->bin . '" does not exist';
    }

    my $icon_id = $self->icons->add_icon(
        catfile( $self->dist_dir, "$launcher->{bin}.ico" ),
        $launcher->bin . '.bat' );

    # Add the icon.
    $self->add_icon(
        name     => $launcher->name,
        filename => $to,
        fragment => "Icons",
        icon_id  => $icon_id
    );

    return $self;
} ## end sub install_launcher

=pod

=head3 install_website

  $self->install_website(
      name       => 'Strawberry Perl Website',
      url        => 'http://strawberryperl.com/',
      icon_file  => 'Strawberry Perl Website.ico',
      icon_index => 1,
  );

The C<install_website> param is used to install a "Start" menu entry
that will load a website using the default system browser.

The compulsory 'name' param should be the name of the website, and will
be the labelled displayed in the "Start" menu.

The compulsory 'url' param is the fully resolved URL for the website.

The optional 'icon_file' param should be the path to a file that contains the
icon for the website.

The optional 'icon_index' param should be the icon index within the icon file.
This param is optional even if the 'icon_file' param has been provided, by
default the first icon in the file will be used.

Returns true on success, or throws an exception on error.

=cut

sub install_website {
    my $self    = shift;
    my $website = Perl::Dist::Asset::Website->new(
        parent => $self,
        @_,
    );

    my $filename = catfile( $self->image_dir, "win32", $website->file );

    # Write the file directly to the image
    $website->write( $filename );

    # Add the file.
    $self->add_file(
        source   => $filename,
        fragment => "Win32Extras"
    );

    my $icon_id = $self->icons->add_icon( $website->icon_file, $filename );

    # Add the icon.
    $self->add_icon(
        name     => $website->name,
        filename => $filename,
        fragment => "Icons",
        icon_id  => $icon_id,
    );

    return $filename;
} ## end sub install_website


#####################################################################
# Package Generation

sub write {
    my $self = shift;
    $self->{output_file} ||= [];
    if ( $self->zip ) {
        push @{ $self->{output_file} }, $self->write_zip;
    }
    if ( $self->msi ) {
        push @{ $self->{output_file} }, $self->write_msi;
    }
    return 1;
}

=pod

=head2 write_zip

The C<write_zip> method is used to generate a standalone .zip file
containing the entire distribution, for situations in which a full
installer executable is not wanted (such as for "Portable Perl"
type installations).

The executable file is written to the output directory, and the location
of the file is printed to STDOUT.

Returns true or throws an exception or error.

=cut

sub write_zip {
    my $self = shift;
    my $file =
      catfile( $self->output_dir, $self->output_base_filename . '.zip' );
    $self->trace_line( 1, "Generating zip at $file\n" );

    # Create the archive
    my $zip = Archive::Zip->new;

    # Add the image directory to the root
    $zip->addTree( $self->image_dir, '' );

    # Set max compression for all members
    foreach my $member ( $zip->members ) {
        next if $member->isDirectory;
        $member->desiredCompressionLevel( 9 );
    }

    # Write out the file name
    $zip->writeToFileNamed( $file );

    return $file;
} ## end sub write_zip

sub add_icon {
    my $self   = shift;
    my %params = @_;
    my ( $vol, $dir, $file, $dir_obj, $dir_id );

    ( $vol, $dir, $file ) = splitpath( $params{filename} );
    $dir_obj = $self->directories->search_dir(
        path_to_find => catdir( $vol, $dir ),
        exact        => 1,
        descend      => 1,
    );
    $dir_id = $dir_obj->id;

    my $id = $params{name};
    $id =~ s{\s}{_}g;

    $self->{fragments}->{Icons}->add_component(
        Perl::Dist::WiX::StartMenuComponent->new(
            sitename    => $self->sitename,
            name        => $params{name},
            target      => "[D_$dir_id]$file",
            id          => $id,
            working_dir => $dir_id,
            trace       => $self->{trace},
            menudir_id  => 'D_App_Menu',
            icon_id     => $params{icon_id},
        ) );

    return $self;
} ## end sub add_icon

sub add_env_path {
    my $self = shift;
    my @path = @_;
    my $dir  = catdir( $self->image_dir, @path );
    unless ( -d $dir ) {
        croak( "PATH directory $dir does not exist" );
    }
    push @{ $self->{env_path} }, [@path];
    return 1;
}

sub get_env_path {
    my $self = shift;
    return join ';',
      map { catdir( $self->image_dir, @$_ ) } @{ $self->env_path };
}

#####################################################################
# Patch Support

# By default only use the default (as a default...)
sub patch_include_path {
    my $self  = shift;
    my $share = File::ShareDir::dist_dir( 'Perl-Dist' );
    my $path  = catdir( $share, 'default', );
    unless ( -d $path ) {
        die( "Directory $path does not exist" );
    }
    return [$path];
}

sub patch_pathlist {
    my $self = shift;
    return File::PathList->new( paths => $self->patch_include_path, );
}

# Cache this
sub patch_template {
    $_[0]->{template_toolkit}
      or $_[0]->{template_toolkit} = Template->new(
        INCLUDE_PATH => $_[0]->patch_include_path,
        ABSOLUTE     => 1,
      );
}

sub patch_file {
    my $self     = shift;
    my $file     = shift;
    my $file_tt  = $file . '.tt';
    my $dir      = shift;
    my $to       = catfile( $dir, $file );
    my $pathlist = $self->patch_pathlist;

    # Locate the source file
    my $from    = $pathlist->find_file( $file );
    my $from_tt = $pathlist->find_file( $file_tt );
    unless ( defined $from and defined $from_tt ) {
        die "Missing or invalid file $file or $file_tt in pathlist search";
    }

    if ( $from_tt ne '' ) {

        # Generate the file
        my $hash = _HASH( shift ) || {};
        my ( $fh, $output ) = File::Temp::tempfile();
        $self->trace_line( 2,
            "Generating $from_tt into temp file $output\n" );
        $self->patch_template->process( $from_tt, { %$hash, self => $self },
            $fh, )
          or die "Template processing failed for $from_tt";

        # Copy the file to the final location
        $fh->close;
        $self->_copy( $output => $to );

    } elsif ( $from ne '' ) {

        # Simple copy of the regular file to the target location
        $self->_copy( $from => $to );

    } else {
        die "Failed to find file $file";
    }

    return 1;
} ## end sub patch_file

sub image_dir_url {
    my $self = shift;
    return URI::file->new( $self->image_dir )->as_string;
}

# This is a temporary hack
sub image_dir_quotemeta {
    my $self   = shift;
    my $string = $self->image_dir;
    $string =~ s/\\/\\\\/g;
    return $string;
}

#####################################################################
# Support Methods

sub dir {
    catdir( shift->image_dir, @_ );
}

sub file {
    catfile( shift->image_dir, @_ );
}

sub user_agent {
    my $self = shift;
    unless ( $self->{user_agent} ) {
        if ( $self->{user_agent_cache} ) {
          SCOPE: {

                # Temporarily set $ENV{HOME} to the File::HomeDir
                # version while loading the module.
                local $ENV{HOME} ||= File::HomeDir->my_home;
                require LWP::UserAgent::WithCache;
            }
            $self->{user_agent} = LWP::UserAgent::WithCache->new( {
                    namespace          => 'perl-dist',
                    cache_root         => $self->user_agent_directory,
                    cache_depth        => 0,
                    default_expires_in => 86400 * 30,
                    show_progress      => 1,
            } );
        } else {
            $self->{user_agent} = LWP::UserAgent->new(
                agent => ref( $self ) . '/' . ( $VERSION || '0.00' ),
                timeout       => 30,
                show_progress => 1,
            );
        }
    } ## end unless ( $self->{user_agent...
    return $self->{user_agent};
} ## end sub user_agent

sub user_agent_cache {
    $_[0]->{user_agent_cache};
}

sub user_agent_directory {
    my $self = shift;
    my $path = ref( $self );
    $path =~ s/::/-/g;
    my $dir = File::Spec->catdir( File::HomeDir->my_data, 'Perl', $path, );

    unless ( -d $dir ) {
        unless ( File::Path::mkpath( $dir, { verbose => 0 } ) ) {
            die( "Failed to create $dir" );
        }
    }
    unless ( -w $dir ) {
        die( "No write permissions for LWP::UserAgent cache '$dir'" );
    }
    return $dir;
} ## end sub user_agent_directory

sub _mirror {
    my ( $self, $url, $dir ) = @_;

    my $no_display_trace = 0;
    my (
        undef, undef, undef, $sub,  undef,
        undef, undef, undef, undef, undef
    ) = caller( 0 );
    if ( $sub eq 'install_par' ) { $no_display_trace = 1; }

    my $file = $url;
    $file =~ s|.+\/||;
    my $target = catfile( $dir, $file );
    if ( $self->offline and -f $target ) {
        return $target;
    }
    if ( $self->offline and !$url =~ m|^file://| ) {
        $self->trace_line( 0,
            "Error: Currently offline, cannot download.\n" );
        exit( 0 );
    }
    File::Path::mkpath( $dir );
    $| = 1;

    $self->trace_line( 2, "Downloading file $url...\n", $no_display_trace );
    if ( $url =~ m|^file://| ) {

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

        # my $ua = $self->user_agent;
        my $ua = LWP::UserAgent->new;
        my $r = $ua->mirror( $url, $target );
        if ( $r->is_error ) {
            $self->trace_line( 0,
                "    Error getting $url:\n" . $r->as_string . "\n" );
        } elsif ( $r->code == HTTP::Status::RC_NOT_MODIFIED ) {
            $self->trace_line( 2, "(already up to date)\n",
                $no_display_trace );
        }
    } ## end else [ if ( $url =~ m|^file://|)

    return $target;
} ## end sub _mirror

sub _copy {
    my ( $self, $from, $to ) = @_;
    my $basedir = File::Basename::dirname( $to );
    File::Path::mkpath( $basedir ) unless -e $basedir;
    $self->trace_line( 2, "Copying $from to $to\n" );

    if ( -f $to and !-w $to ) {
        require Win32::File::Object;

        # Make sure it isn't readonly
        my $file = Win32::File::Object->new( $to, 1 );
        my $readonly = $file->readonly;
        $file->readonly( 0 );

        # Do the actual copy
        File::Copy::Recursive::rcopy( $from, $to ) or die $!;

        # Set it back to what it was
        $file->readonly( $readonly );
    } else {
        File::Copy::Recursive::rcopy( $from, $to ) or die $!;
    }
    return 1;
} ## end sub _copy

sub _move {
    my ( $self, $from, $to ) = @_;
    my $basedir = File::Basename::dirname( $to );
    File::Path::mkpath( $basedir ) unless -e $basedir;
    $self->trace_line( 2, "Moving $from to $to\n" );
    File::Copy::Recursive::rmove( $from, $to ) or die $!;
}

sub _pushd {
    my $self = shift;
    my $dir  = catdir( @_ );
    $self->trace_line( 2, "Lexically changing directory to $dir...\n" );
    return File::pushd::pushd( $dir );
}


sub _make {
    my $self   = shift;
    my @params = @_;
    $self->trace_line( 2,
        join( ' ', '>', $self->bin_make, @params ) . "\n" );
    $self->_run3( $self->bin_make, @params ) or die "make failed";
    die "make failed (OS error)" if ( $? >> 8 );
    return 1;
}

sub _perl {
    my $self   = shift;
    my @params = @_;
    $self->trace_line( 2,
        join( ' ', '>', $self->bin_perl, @params ) . "\n" );
    $self->_run3( $self->bin_perl, @params ) or die "perl failed";
    die "perl failed (OS error)" if ( $? >> 8 );
    return 1;
}

sub _run3 {
    my $self = shift;

    # Remove any Perl installs from PATH to prevent
    # "which" discovering stuff it shouldn't.
    my @path = split /;/, $ENV{PATH};
    my @keep = ();
    foreach my $p ( @path ) {

        # Strip any path that doesn't exist
        next unless -d $p;

        # Strip any path that contains either dmake or perl.exe.
        # This should remove both the ...\c\bin and ...\perl\bin
        # parts of the paths that Vanilla/Strawberry added.
        next if -f catfile( $p, 'dmake.exe' );
        next if -f catfile( $p, 'perl.exe' );

        push @keep, $p;
    } ## end foreach my $p ( @path )

    # Reset the environment
    local $ENV{LIB}      = undef;
    local $ENV{INCLUDE}  = undef;
    local $ENV{PERL5LIB} = undef;
    local $ENV{PATH}     = $self->get_env_path . ';' . join( ';', @keep );

    # Execute the child process
    return IPC::Run3::run3( [@_], \undef, $self->debug_stdout,
        $self->debug_stderr, );
} ## end sub _run3

sub _convert_name {
    my $name     = shift;
    my @paths    = split( /\//, $name );
    my $filename = pop( @paths );
    $filename = '' unless defined( $filename );
    my $local_dirs = @paths ? catdir( @paths ) : q{};
    my $local_name = catpath( '', $local_dirs, $filename );
    $local_name = rel2abs( $local_name );
    return $local_name;
}

sub _extract {
    my ( $self, $from, $to ) = @_;
    File::Path::mkpath( $to );
    my $wd = $self->_pushd( $to );

    my @filelist;

    $|++;
    $self->trace_line( 2, "Extracting $from...\n" );
    if ( $from =~ m{\.zip\z} ) {
        my $zip = Archive::Zip->new( $from );

# I can't just do an extractTree here, as I'm trying to keep track of what got extracted.
        my @members = $zip->members();

        foreach my $member ( @members ) {
            my $filename = $member->fileName();
            $filename = _convert_name( $filename )
              ;                        # Converts filename to Windows format.
            my $status = $member->extractToFileNamed( $filename );
            if ( $status != AZ_OK ) {
                die "Error in archive extraction";
            }
            push @filelist, $filename;
        }

    } elsif ( $from =~ m{\.tar\.gz|\.tgz} ) {
        local $Archive::Tar::CHMOD = 0;
        my @fl = @filelist = Archive::Tar->extract_archive( $from, 1 );
        @filelist = map { catfile( $to, $_ ) } @fl;
        if ( !@filelist ) {
            die "Error in archive extraction";
        }

    } else {
        die "Didn't recognize archive type for $from";
    }
    return @filelist;
} ## end sub _extract

sub _extract_filemap {
    my ( $self, $archive, $filemap, $basedir, $file_only ) = @_;

    my @files;

    if ( $archive =~ m{\.zip\z} ) {

        my $zip = Archive::Zip->new( $archive );
        my $wd  = $self->_pushd( $basedir );
        while ( my ( $f, $t ) = each %$filemap ) {
            $self->trace_line( 2, "Extracting $f to $t\n" );
            my $dest = catfile( $basedir, $t );

            my @members = $zip->membersMatching( "^\Q$f" );

            foreach my $member ( @members ) {
                my $filename = $member->fileName();
                $filename =~ s{^\Q$f}{$dest};
                $filename = _convert_name( $filename );
                my $status = $member->extractToFileNamed( $filename );

                if ( $status != AZ_OK ) {
                    die "Error in archive extraction";
                }
                push @files, $filename;
            }
        } ## end while ( my ( $f, $t ) = each...

    } elsif ( $archive =~ m{\.tar\.gz|\.tgz} ) {
        local $Archive::Tar::CHMOD = 0;
        my $tar = Archive::Tar->new( $archive );
        for my $file ( $tar->get_files ) {
            my $f       = $file->full_path;
            my $canon_f = File::Spec::Unix->canonpath( $f );
            for my $tgt ( keys %$filemap ) {
                my $canon_tgt = File::Spec::Unix->canonpath( $tgt );
                my $t;

                # say "matching $canon_f vs $canon_tgt";
                if ( $file_only ) {
                    next
                      unless $canon_f =~ m{\A([^/]+[/])?\Q$canon_tgt\E\z}i;
                    ( $t = $canon_f ) =~
                      s{\A([^/]+[/])?\Q$canon_tgt\E\z}{$filemap->{$tgt}}i;

                } else {
                    next unless $canon_f =~ m{\A([^/]+[/])?\Q$canon_tgt\E}i;
                    ( $t = $canon_f ) =~
                      s{\A([^/]+[/])?\Q$canon_tgt\E}{$filemap->{$tgt}}i;
                }
                my $full_t = catfile( $basedir, $t );
                $self->trace_line( 2, "Extracting $f to $full_t\n" );
                $tar->extract_file( $f, $full_t );
                push @files, $full_t;
            } ## end for my $tgt ( keys %$filemap)
        } ## end for my $file ( $tar->get_files)

    } else {
        die "Didn't recognize archive type for $archive";
    }

    return @files;
} ## end sub _extract_filemap

# Convert a .dll to an .a file
sub _dll_to_a {
    my $self   = shift;
    my %params = @_;
    unless ( $self->bin_dlltool ) {
        croak( "Required method bin_dlltool is not defined" );
    }

    my @files;

    # Source file
    my $source = $params{source};
    if ( $source and !$source =~ /\.dll$/ ) {
        croak( "Missing or invalid source param" );
    }

    # Target .dll file
    my $dll = $params{dll};
    unless ( $dll and $dll =~ /\.dll/ ) {
        croak( "Missing or invalid .dll file" );
    }

    # Target .def file
    my $def = $params{def};
    unless ( $def and $def =~ /\.def$/ ) {
        croak( "Missing or invalid .def file" );
    }

    # Target .a file
    my $_a = $params{a};
    unless ( $_a and $_a =~ /\.a$/ ) {
        croak( "Missing or invalid .a file" );
    }

    # Step 1 - Copy the source .dll to the target if needed
    unless ( ( $source and -f $source ) or -f $dll ) {
        croak( "Need either a source or dll param" );
    }
    if ( $source ) {
        $self->_move( $source => $dll );
        push @files, $dll;
    }

    # Step 2 - Generate the .def from the .dll
  SCOPE: {
        my $bin = $self->bin_pexports;
        unless ( $bin ) {
            croak( "Required method bin_pexports is not defined" );
        }
        my $ok = !system( "$bin $dll > $def" );
        unless ( $ok and -f $def ) {
            croak( "Failed to generate .def file" );
        }

        push @files, $def;
    } ## end SCOPE:

    # Step 3 - Generate the .a from the .def
  SCOPE: {
        my $bin = $self->bin_dlltool;
        unless ( $bin ) {
            croak( "Required method bin_dlltool is not defined" );
        }
        my $ok =
          !system( "$bin -dllname $dll --def $def --output-lib $_a" );
        unless ( $ok and -f $_a ) {
            croak( "Failed to generate .a file" );
        }

        push @files, $_a;
    } ## end SCOPE:

    return @files;
} ## end sub _dll_to_a

sub make_path {
    my $class = shift;
    my $dir = rel2abs( catdir( curdir, @_, ), );
    File::Path::mkpath( $dir ) unless -d $dir;
    unless ( -d $dir ) {
        croak( "Failed to make_path for $dir" );
    }
    return $dir;
}

sub remake_path {
    my $class = shift;
    my $dir = rel2abs( catdir( curdir, @_ ) );
    File::Remove::remove( \1, $dir ) if -d $dir;
    File::Path::mkpath( $dir );

    unless ( -d $dir ) {
        croak( "Failed to make_path for $dir" );
    }
    return $dir;
}

1;

=pod

=head1 SUPPORT

No support of any kind is provided for this module

=head1 AUTHORS

Curtis Jewell E<lt>csjewell@cpan.orgE<gt>

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Perl::Dist>, L<Perl::Dist::Inno>, L<http://ali.as/>

=head1 COPYRIGHT

Copyright 2009 Curtis Jewell.

Copyright 2008-2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
