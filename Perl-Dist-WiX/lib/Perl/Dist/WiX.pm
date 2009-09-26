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
		app_publisher_url => 'http:/myperl.invalid/',
		msi_directory_tree_additions => [ qw(
		  c\bin\program
		  perl\lib\Acme
		)],
	);

	# Creates the distribution
	$bb->run();

=head1 INTERFACE

=cut

#<<<
use     5.008001;
use     strict;
use     warnings;
use     vars                  qw( $VERSION                      );
use     parent                qw( Perl::Dist::WiX::Installer 
                                  Perl::Dist::WiX::BuildPerl
                                  Perl::Dist::WiX::Checkpoint
                                  Perl::Dist::WiX::Libraries
                                  Perl::Dist::WiX::Installation
                                  Perl::Dist::WiX::ReleaseNotes );
use     Archive::Zip          qw( :ERROR_CODES                  );
use     English               qw( -no_match_vars                );
use     List::MoreUtils       qw( any none uniq                 );
use     Params::Util          qw( 
	_HASH _STRING _INSTANCE _IDENTIFIER      
);
use     Readonly              qw( Readonly                      );
use     Storable              qw( retrieve                      );
use     File::Spec::Functions qw(
	catdir catfile catpath tmpdir splitpath rel2abs curdir
);
use     Archive::Tar     1.42 qw();
use     File::Remove          qw();
use     File::pushd           qw();
use     File::ShareDir        qw();
use     File::Copy::Recursive qw();
use     File::PathList        qw();
use     HTTP::Status          qw();
use     IO::String            qw();
use     IO::Handle            qw();
use     LWP::UserAgent        qw();
use     LWP::Online           qw();
use     Module::CoreList 2.18 qw();
use     PAR::Dist             qw();
use     Probe::Perl           qw();
use     SelectSaver           qw();
use     Template              qw();
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
require WiX3::XML::GeneratesGUID::Object;
require WiX3::Traceable;

our $VERSION = '1.090_103';
$VERSION = eval $VERSION; ## no critic (ProhibitStringyEval)

use Object::Tiny qw(
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
  forceperl
  checkpoint_before
  checkpoint_after
  checkpoint_stop
  tasklist  
  filters
  build_number
  beta_number
  trace
  build_start_time
  perl_config_cf_email
  perl_config_cf_by
  toolchain
);
#  Don't need to put distributions_installed in here.

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

This routine may take a few minutes to run.

An example of the most likely attributes that will be specified is in the 
SYNOPSIS.

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
first thing on the line, and when an error occurs and an exception 
object is printed, a stack trace will be printed as well.

Setting this parameter to 3 or above will print out the filename and 
line number after the trace level on those lines that require a trace 
level of 3 or above to print.

Setting this parameter to 5 or above will print out the filename and 
line number on every line.

Default is 1 if not set.

=item * perl_version

The C<perl_version> parameter specifies what version of perl is 
downloaded and built.  Legal values for this parameter are '589', 
'5100', and '5101' (for 5.8.9, 5.10.0, and 5.10.1, respectively.)

This parameter defaults to '5101' if not specified.

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
device. This creates a distribution in zip format.

=item * zip

The optional boolean C<zip> param is used to indicate that a zip
distribution package should be created.

=item * msi

The optional boolean C<msi> param is used to indicate that a Windows
Installer distribution package (otherwise known as an msi file) should 
be created.

=item * exe

The optional boolean C<exe> param is unused at the moment.

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
a debugging MSI (one that creates a log in $ENV{TEMP} upon execution
in Windows Installer 4.0 or above) will be created if C<msi> is also 
true.

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

=item * perl_config_cf_email

The optional C<perl_config_cf_email> parameter specifies the e-mail
of the person building the perl distribution defined by this object.

It is compiled into the perl binary as the C<cf_email> option accessible
through C<perl -V:cf_email>.

The username (the part before the at sign) of this parameter also sets the
C<cf_by> option.

If not defined, this is set to anonymous@unknown.builder.invalid.

=back

The C<new> constructor returns a B<Perl::Dist::WiX> object, which you
should then call C<run> on to generate the distribution.

=cut

sub new { ## no critic 'ProhibitExcessComplexity'
	my $class  = shift;
	my %params = (
		trace            => 1,
		build_start_time => localtime,
		temp_dir         => catdir( tmpdir(), 'perldist' ),
		@_,
	);

	$params{misc} ||= WiX3::Traceable->new( tracelevel => $params{trace} );

	# Announce that we're starting.
	{
		my $time = scalar localtime;
		$params{misc}->trace_line( 0, "Starting build at $time.\n" );
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

	unless ( defined $params{download_dir} ) {
		$params{download_dir} = catdir( $params{temp_dir}, 'download' );
		File::Path::mkpath( $params{download_dir} );
	}
	unless ( defined $params{binary_root} ) {
		if ( $params{offline} ) {
			$params{binary_root} = q{};
		} else {
			$params{binary_root} = 'http://strawberryperl.com/package';
		}
	}
	unless ( defined $params{build_dir} ) {
		$params{build_dir} = catdir( $params{temp_dir}, 'build' );
		$class->remake_path( $params{build_dir} );
	}
	if ( $params{build_dir} =~ m{[.]}ms ) {
		PDWiX::Parameter->throw(
			parameter => 'build_dir: Cannot be '
			  . 'a directory that has a . in the name.',
			where => '->new'
		);
	}
	unless ( defined $params{output_dir} ) {
		$params{output_dir} = catdir( $params{temp_dir}, 'output' );
		$params{misc}->trace_line( 1,
			"Wait a second while we empty the output directory...\n" );
		$class->remake_path( $params{output_dir} );
	}
	unless ( defined $params{fragment_dir} ) {
		$params{fragment_dir} =        # To store the WiX fragments in.
		  catdir( $params{temp_dir}, 'fragments' );
		$class->remake_path( $params{fragment_dir} );
	}
	if ( defined $params{image_dir} ) {
		my $perl_location = lc Probe::Perl->find_perl_interpreter();
		$params{misc}
		  ->trace_line( 3, "Currently executing perl: $perl_location\n" );
		my $our_perl_location =
		  lc catfile( $params{image_dir}, qw(perl bin perl.exe) );
		$params{misc}->trace_line( 3,
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

		$class->remake_path( $params{image_dir} );
	} ## end if ( defined $params{image_dir...})

	my $tasklist = [

		# Final initialization
		'final_initialization',

		# Install the core C toolchain
		'install_c_toolchain',

		# Install any additional C libraries
		'install_c_libraries',

		# Install the Perl binary
		'install_perl',

		# Install the Perl toolchain
		'install_perl_toolchain',

		# Install additional Perl modules
		'install_cpan_upgrades',

		# Install the Win32 extras
		'install_win32_extras',

		# Apply optional portability support
		'install_portable',

		# Remove waste and temporary files
		'remove_waste',

		# Create the distribution list
		'create_distribution_list',

		# Regenerate file fragments
		'regenerate_fragments',

		# Write out the distributions
		'write',
	];

	my $self = bless {
		perl_version => '5101',
		offline      => LWP::Online::offline(),
		pdw_version  => $Perl::Dist::WiX::VERSION,
		pdw_class    => $class,
		fragments    => {},
		beta_number  => 0,
		force        => 0,
		forceperl    => 0,
		exe          => 0,
		msi               => 1,        # Goal of Perl::Dist::WiX is to make an MSI.
		checkpoint_before => 0,
		checkpoint_after        => [0],
		checkpoint_stop         => 0,
		output_file             => [],
		env_path                => [],
		distributions_installed => [],
		output_dir              => rel2abs( curdir, ),
		tasklist                => $tasklist,
		%params,
	}, $class;

	# Apply defaults

	unless ( ( defined $self->{perl_config_cf_email} )
		&& ( $self->{perl_config_cf_email} =~ m/\A.*@.*\z/msx ) )
	{
		$self->{perl_config_cf_email} = 'anonymous@unknown.builder.invalid';
	}
	( $self->{perl_config_cf_by} ) =
	  $self->{perl_config_cf_email} =~ m/\A(.*)@.*\z/msx;

	unless ( defined $self->default_group_name ) {
		$self->{default_group_name} = $self->app_name;
	}
	unless ( _STRING( $self->msi_license_file ) ) {
		$self->{msi_license_file} =
		  catfile( $self->wix_dist_dir, 'License.rtf' );
	}

	# Check and default params
	unless ( _IDENTIFIER( $self->app_id ) ) {
		PDWiX::Parameter->throw(
			parameter => 'app_id',
			where     => '::Installer->new'
		);
	}
	$self->_check_string_parameter( $self->app_name,      'app_name' );
	$self->_check_string_parameter( $self->app_ver_name,  'app_ver_name' );
	$self->_check_string_parameter( $self->app_publisher, 'app_publisher' );
	$self->_check_string_parameter( $self->app_publisher_url,
		'app_publisher_url' );

	if ( $self->app_name =~ m{[\\/:*"<>|]}msx ) {
		PDWiX::Parameter->throw(
			parameter => 'app_name: Contains characters invalid '
			  . 'for Windows file/directory names',
			where => '::Installer->new'
		);
	}

	$self->_check_string_parameter( $self->default_group_name,
		'default_group_name' );
	$self->_check_string_parameter( $self->output_dir, 'output_dir' );
	unless ( -d $self->output_dir ) {
		$self->trace_line( 0,
			'Directory does not exist: ' . $self->output_dir . "\n" );
		PDWiX::Parameter->throw(
			parameter => 'output_dir: Directory does not exist',
			where     => '::Installer->new'
		);
	}
	unless ( -w $self->output_dir ) {
		PDWiX->throw('The output_dir directory is not writable');
	}
	$self->_check_string_parameter( $self->output_base_filename,
		'output_base_filename' );
	$self->_check_string_parameter( $self->source_dir, 'source_dir' );
	unless ( -d $self->source_dir ) {
		$self->trace_line( 0,
			'Directory does not exist: ' . $self->source_dir . "\n" );
		PDWiX::Parameter->throw(
			parameter => 'source_dir: Directory does not exist',
			where     => '::Installer->new'
		);
	}
	$self->_check_string_parameter( $self->fragment_dir, 'fragment_dir' );
	unless ( -d $self->fragment_dir ) {
		$self->trace_line( 0,
			'Directory does not exist: ' . $self->fragment_dir . "\n" );
		PDWiX::Parameter->throw(
			parameter => 'fragment_dir: Directory does not exist',
			where     => '::Installer->new'
		);
	}

	# Check the version of Perl to build
	unless ( defined $self->build_number ) {
		PDWiX::Parameter->throw(
			parameter => 'build_number',
			where     => '->new'
		);
	}
	unless ( $self->perl_version_literal ) {
		PDWiX::Parameter->throw(
			parameter => 'perl_version_literal: Failed to resolve',
			where     => '->new'
		);
	}
	unless ( $self->perl_version_human ) {
		PDWiX::Parameter->throw(
			parameter => 'perl_version_human: Failed to resolve',
			where     => '->new'
		);
	}
	unless ( $self->can( 'install_perl_' . $self->perl_version ) ) {
		PDWiX->throw(
			"$class does not support Perl " . $self->perl_version );
	}

	# Find the core list
	my $corelist_version = $self->perl_version_literal + 0;
	$self->{perl_version_corelist} =
	  $Module::CoreList::version{$corelist_version};
	unless ( _HASH( $self->{perl_version_corelist} ) ) {
		PDWiX->throw( 'Failed to resolve Module::CoreList hash for '
			  . $self->perl_version_human );
	}

	# Apply more defaults
	unless ( defined $self->debug_stdout ) {
		$self->{debug_stdout} = catfile( $self->output_dir, 'debug.out' );
	}
	unless ( defined $self->debug_stderr ) {
		$self->{debug_stderr} = catfile( $self->output_dir, 'debug.err' );
	}
	unless ( defined $self->zip ) {
		$self->{zip} = $self->portable ? 1 : 0;
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
	if ( not $self->cpan ) {
		if ( $self->offline ) {
			PDWiX::Parameter->throw(
				parameter => 'cpan: Required if offline => 1',
				where     => '->new'
			);
		} else {
			$self->{cpan} = URI->new('http://cpan.strawberryperl.com/');
		}
	}

	# If we have a file:// url for the CPAN, move the
	# sources directory out of the way.

	if ( $self->cpan->as_string =~ m{\Afile://}mxsi ) {
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

	# Check params
	$self->_check_string_parameter( $self->download_dir, 'download_dir' );
	unless ( defined $self->modules_dir ) {
		$self->{modules_dir} = catdir( $self->download_dir, 'modules' );
	}
	unless ( _STRING( $self->modules_dir ) ) {
		PDWiX::Parameter->throw(
			parameter => 'modules_dir',
			where     => '->new'
		);
	}
	$self->_check_string_parameter( $self->image_dir, 'image_dir' );
	if ( $self->image_dir =~ /\s/ms ) {
		PDWiX::Parameter->throw(
			parameter => 'image_dir: Spaces are not allowed',
			where     => '->new'
		);
	}
	unless ( defined $self->license_dir ) {
		$self->{license_dir} = catdir( $self->image_dir, 'licenses' );
	}
	unless ( _STRING( $self->license_dir ) ) {
		PDWiX::Parameter->throw(
			parameter => 'license_dir',
			where     => '->new'
		);
	}
	$self->_check_string_parameter( $self->build_dir, 'build_dir' );
	if ( $self->build_dir =~ /\s/ms ) {
		PDWiX::Parameter->throw(
			parameter => 'build_dir: Spaces are not allowed',
			where     => '->new'
		);
	}
	unless ( _INSTANCE( $self->user_agent, 'LWP::UserAgent' ) ) {
		PDWiX::Parameter->throw(
			parameter => 'user_agent',
			where     => '->new'
		);
	}
	unless ( _INSTANCE( $self->cpan, 'URI' ) ) {
		PDWiX::Parameter->throw(
			parameter => 'cpan: Not a URI instance',
			where     => '->new'
		);
	}
	unless ( $self->cpan->as_string =~ m{\/\z}ms ) {
		PDWiX::Parameter->throw(
			parameter => 'cpan: Missing trailing slash',
			where     => '->new'
		);
	}

	# Clear the previous build
	if ( -d $self->image_dir ) {
		$self->trace_line( 1,
			'Removing previous ' . $self->image_dir . "\n" );
		File::Remove::remove( \1, $self->image_dir );
	} else {
		$self->trace_line( 1,
			'No previous ' . $self->image_dir . " found\n" );
	}

	return $self;
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

#####################################################################
# Upstream Binary Packages (Mirrored)

Readonly my %PACKAGES => (
	'dmake'         => 'dmake-4.8-20070327-SHAY.zip',
	'gcc-core'      => 'gcc-core-3.4.5-20060117-3.tar.gz',
	'gcc-g++'       => 'gcc-g++-3.4.5-20060117-3.tar.gz',
	'mingw-make'    => 'mingw32-make-3.81-2.tar.gz',
	'binutils'      => 'binutils-2.17.50-20060824-1.tar.gz',
	'mingw-runtime' => 'mingw-runtime-3.13.tar.gz',
	'w32api'        => 'w32api-3.10.tar.gz',
);

sub final_initialization {
	my $self = shift;

	## no critic(ProtectPrivateSubs)
	# Set element collections
	$self->trace_line( 2, "Creating in-memory directory tree...\n" );
	Perl::Dist::WiX::DirectoryTree2->_clear_instance();
	$self->{directories} = Perl::Dist::WiX::DirectoryTree2->new(
		app_dir  => $self->image_dir,
		app_name => $self->app_name,
	)->initialize_tree( $self->perl_version );

	$self->{fragments}->{StartMenuIcons} =
	  Perl::Dist::WiX::Fragment::StartMenu->new(
		directory_id => 'D_App_Menu', );
	$self->{fragments}->{Environment} =
	  Perl::Dist::WiX::Fragment::Environment->new();
	$self->{fragments}->{Win32Extras} =
	  Perl::Dist::WiX::Fragment::Files->new(
		id    => 'Win32Extras',
		files => File::List::Object->new(),
	  );

	$self->{fragments}->{CreateCpan} =
	  Perl::Dist::WiX::Fragment::CreateFolder->new(
		directory_id => 'Cpan',
		id           => 'CPANFolder',
	  );
	$self->{fragments}->{CreateCpanplus} =
	  Perl::Dist::WiX::Fragment::CreateFolder->new(
		directory_id => 'Cpanplus',
		id           => 'CPANPLUSFolder',
	  ) if ( 5100 <= $self->perl_version );

	$self->{icons} = $self->{fragments}->{StartMenuIcons}->get_icons();

	if ( defined $self->msi_product_icon ) {
		$self->icons->add_icon( $self->msi_product_icon );
	}

	# Clear the par cache, just to be safe.
	# Sometimes, if not cleared, PAR fails tests.
	my $par_temp = catdir( $ENV{TEMP}, 'par-' . Win32::LoginName() );
	if ( -d $par_temp ) {
		$self->trace_line( 1, 'Removing ' . $par_temp . "\n" );
		File::Remove::remove( \1, $par_temp );
	}

	# Initialize the build
	for my $d ( $self->download_dir, $self->image_dir, $self->modules_dir,
		$self->license_dir, catdir( $self->image_dir, 'cpan' ),
	  )
	{
		next if -d $d;
		File::Path::mkpath($d);
	}

	my $cpanplus_dir = catdir( $self->image_dir, 'cpanplus' );
	if ( ( 5100 <= $self->perl_version ) and ( not -d $cpanplus_dir ) ) {
		File::Path::mkpath($cpanplus_dir);
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
	  catdir ( $self->image_dir, qw{ c    bin         startup mac   } ) . q{\\},
	  catdir ( $self->image_dir, qw{ c    bin         startup msdos } ) . q{\\},
	  catdir ( $self->image_dir, qw{ c    bin         startup os2   } ) . q{\\},
	  catdir ( $self->image_dir, qw{ c    bin         startup qssl  } ) . q{\\},
	  catdir ( $self->image_dir, qw{ c    bin         startup tos   } ) . q{\\},
	  catdir ( $self->image_dir, qw{ c    libexec     gcc     mingw32 3.4.5 install-tools}) . q{\\},
	  catfile( $self->image_dir, qw{ c    COPYING     } ),
	  catfile( $self->image_dir, qw{ c    COPYING.LIB } ),
	  catfile( $self->image_dir, qw{ c    bin         gccbug  } ),
	  catfile( $self->image_dir, qw{ c    bin         mingw32-gcc-3.4.5  } ),
	  ;
#>>>

	$self->{filters} = \@filters_array;

	$self->add_env( 'TERM',        'dumb' );
	$self->add_env( 'FTP_PASSIVE', '1' );

	return 1;
} ## end sub final_initialization

sub binary_file {
	unless ( $PACKAGES{ $_[1] } ) {
		PDWiX->throw("Unknown package '$_[1]'");
	}
	return $PACKAGES{ $_[1] };
}

sub binary_url {
	my $self = shift;
	my $file = shift;

	# Check parameters.
	unless ( _STRING($file) ) {
		PDWiX::Parameter->throw(
			parameter => 'file',
			where     => '->binary_url'
		);
	}

	unless ( $file =~ /[.] (zip | gz | tgz | par) \z/imsx ) {

		# Shorthand, map to full file name
		$file = $self->binary_file( $file, @_ );
	}
	return $self->binary_root . q{/} . $file;
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
perl being distributed.  Retrieved from L<Module::CoreList|Module::CoreList>.

=head3 output_file

The list of distributions created as an array reference.

=head3 filters

Provides an array reference of files and directories that will not be
installed.

Initialized in C<new>.

=head3 dist_dir

Provides a shortcut to the location of the shared files directory.

Returns a directory as a string or throws an exception on error.

=cut

sub dist_dir {
	my $self = shift;

	return $self->wix_dist_dir();
}

=head3 wix_dist_dir

Provides a shortcut to the location of the shared files directory.

Returns a directory as a string or throws an exception on error.

=cut

sub wix_dist_dir {
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
# Documentation for accessors

=pod

=head3 offline

The B<Perl::Dist> module has limited ability to build offline, if all
packages have already been downloaded and cached.

The connectedness of the Perl::Dist object is checked automatically
be default using L<LWP::Online|LWP::Online>. It can be overidden 
by providing an offline param to the constructor.

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
which is an alias to the 
L<Perl::Dist::WiX::Installer|Perl::Dist::WiX::Installer> method
C<source_dir>. (although theoretically they can be different,
this is likely to break the user's Perl install)

=cut

sub source_dir {
	return $_[0]->image_dir;
}

# Default the versioned name to an unversioned name
sub app_ver_name {
	my $self = shift;
	if ( $self->{app_ver_name} ) {
		return $self->{app_ver_name};
	}
	return $self->app_name . q{ } . $self->perl_version_human;
}

# Default the output filename to the id plus the current date
sub output_base_filename {
	my $self = shift;
	if ( $self->{output_base_filename} ) {
		return $self->{output_base_filename};
	}
	return
	    $self->app_id . q{-}
	  . $self->perl_version_human . q{-}
	  . $self->output_date_string;
}

#####################################################################
# Perl::Dist::WiX Main Methods

=pod

=head3 perl_version

The C<perl_version> accessor returns the shorthand perl version
as a string (consisting of the three-part version with dots
removed).

Thus Perl 5.8.9 will be "589" and Perl 5.10.0 will return "5100".

=head3 perl_version_literal

The C<perl_version_literal> method returns the literal numeric Perl
version for the distribution.

For Perl 5.8.8 this will be '5.008008', Perl 5.8.9 will be '5.008009',
and for Perl 5.10.0 this will be '5.010000'.

=cut

sub perl_version_literal {
	return {
		589  => '5.008009',
		5100 => '5.010000',
		5101 => '5.010001',
	  }->{ $_[0]->perl_version }
	  || 0;
}

=pod

=head3 perl_version_human

The C<perl_version_human> method returns the "marketing" form
of the Perl version.

This will be either '5.8.9', '5.10.0', or '5.10.1'.

=cut

sub perl_version_human {
	return {
		589  => '5.8.9',
		5100 => '5.10.0',
		5101 => '5.10.1',
	  }->{ $_[0]->perl_version }
	  || 0;
}

=pod

=head3 distribution_version_human

The C<distribution_version_human> method returns the "marketing" form
of the distribution version.

=cut

sub distribution_version_human {
	return
	    $_[0]->perl_version_human . q{.}
	  . $_[0]->build_number
	  . ( $_[0]->portable ? ' Portable' : q{} )
	  . ( $_[0]->beta_number ? ' Beta ' . $_[0]->beta_number : q{} );
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
file deletion logic in C<remove_waste> won't accidentally delete files that
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
	$self->remove_dir(qw{ perl man       });
	$self->remove_dir(qw{ perl html      });
	$self->remove_dir(qw{ c    man       });
	$self->remove_dir(qw{ c    doc       });
	$self->remove_dir(qw{ c    info      });
	$self->remove_dir(qw{ c    contrib   });
	$self->remove_dir(qw{ c    html      });

	$self->trace_line( 2, "  Removing C examples, manifests\n" );
	$self->remove_dir(qw{ c    examples  });
	$self->remove_dir(qw{ c    manifest  });

	$self->trace_line( 2, "  Removing extra dmake/gcc files\n" );
	$self->remove_dir(qw{ c    bin         startup mac   });
	$self->remove_dir(qw{ c    bin         startup msdos });
	$self->remove_dir(qw{ c    bin         startup os2   });
	$self->remove_dir(qw{ c    bin         startup qssl  });
	$self->remove_dir(qw{ c    bin         startup tos   });
	$self->remove_dir(
		qw{ c    libexec     gcc     mingw32 3.4.5 install-tools});

	$self->trace_line( 2, "  Removing redundant files\n" );
	$self->remove_file(qw{ c COPYING     });
	$self->remove_file(qw{ c COPYING.LIB });
	$self->remove_file(qw{ c bin gccbug  });
	$self->remove_file(qw{ c bin mingw32-gcc-3.4.5 });

	$self->trace_line( 2,
		"  Removing CPAN build directories and download caches\n" );
	$self->remove_dir(qw{ cpan sources  });
	$self->remove_dir(qw{ cpan build    });
	$self->remove_file(qw{ cpan cpandb.sql });
	$self->remove_file(qw{ cpan FTPstats.yml });
	$self->remove_file(qw{ cpan cpan_sqlite_log.* });

	# Readding the cpan directory.
	$self->remake_path( catdir( $self->build_dir, 'cpan' ) );

	return 1;
} ## end sub remove_waste

sub remove_dir {
	my $self = shift;
	my $dir  = $self->dir(@_);
	File::Remove::remove( \1, $dir ) if -e $dir;
	return 1;
}

sub remove_file {
	my $self = shift;
	my $file = $self->file(@_);
	File::Remove::remove( \1, $file ) if -e $file;
	return 1;
}

#####################################################################
# Package Generation

sub regenerate_fragments {
	my $self = shift;

	return 1 unless $self->msi;

	# Add the perllocal.pod here, because apparently it's disappearing.
	$self->add_to_fragment( 'perl',
		[ catfile( $self->image_dir(), qw( perl lib perllocal.pod ) ) ] );

	my @fragment_names_regenerate;
	my @fragment_names = keys %{ $self->{fragments} };

	while ( 0 != scalar @fragment_names ) {
		foreach my $name (@fragment_names) {
			my $fragment = $self->{fragments}->{$name};
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
	$self->{output_file} ||= [];

	if ( $self->zip ) {
		push @{ $self->{output_file} }, $self->write_zip;
	}
	if ( $self->msi ) {
		push @{ $self->{output_file} }, $self->write_msi;
	}
	return 1;
} ## end sub write

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
	$dir_id = $self->directories->search_dir(
		path_to_find => catdir( $vol, $dir ),
		exact        => 1,
		descend      => 1,
	)->get_id();

	# Get a legal id.
	my $id = $params{name};
	$id =~ s{\s}{_}msxg;               # Convert whitespace to underlines.

	# Add the start menu icon.
	$self->{fragments}->{StartMenuIcons}->add_shortcut(
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
	return substr rel2abs( $self->image_dir ), 0, 2;
}

sub image_dir_url {
	my $self = shift;
	return URI::file->new( $self->image_dir )->as_string;
}

# This is a temporary hack
sub image_dir_quotemeta {
	my $self   = shift;
	my $string = $self->image_dir;
	$string =~ s{\\}        # Convert a backslash
				{\\\\}gmsx; ## to 2 backslashes.
	return $string;
}

#####################################################################
# Support Methods

sub dir {
	return catdir( shift->image_dir, @_ );
}

sub file {
	return catfile( shift->image_dir, @_ );
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
					default_expires_in => 86_400 * 30,
					show_progress      => 1,
				} );
		} else {
			$self->{user_agent} = LWP::UserAgent->new(
				agent => ref($self) . q{/} . ( $VERSION || '0.00' ),
				timeout       => 30,
				show_progress => 1,
			);
		}
	} ## end unless ( $self->{user_agent...})
	return $self->{user_agent};
} ## end sub user_agent

sub user_agent_cache {
	return $_[0]->{user_agent_cache};
}

sub user_agent_directory {
	my $self = shift;

# Create a legal path out of the object's class name under {Application Data}/Perl.
	my $path = ref $self;
	$path =~ s{::}{-}gmsx;             # Changes all :: to -.
	my $dir = File::Spec->catdir( File::HomeDir->my_data, 'Perl', $path, );

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
	local $ENV{PATH}     = $self->get_env_path . q{;} . join q{;}, @keep;

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

sub make_path {
	my $class = shift;
	my $dir = rel2abs( catdir( curdir, @_, ), );
	File::Path::mkpath($dir) unless -d $dir;
	unless ( -d $dir ) {
		PDWiX->throw("Failed to make_path for $dir");
	}
	return $dir;
}

sub remake_path {
	my $class = shift;
	my $dir = rel2abs( catdir( curdir, @_ ) );
	File::Remove::remove( \1, $dir ) if -d $dir;
	File::Path::mkpath($dir);

	unless ( -d $dir ) {
		PDWiX->throw("Failed to remake_path for $dir");
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

Create a distribution for handling the XML-generating parts 
of Perl::Dist::WiX and depend on it (1.100? 2.000?)

=item 2.

Have an option to have WiX installed non-core modules install in a 
'vendor path' (1.010)

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
