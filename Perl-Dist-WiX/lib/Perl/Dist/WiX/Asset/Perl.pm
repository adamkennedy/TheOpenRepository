package Perl::Dist::WiX::Asset::Perl;

# Perl::Dist asset for the Perl source code itself

use Moose;
use MooseX::Types::Moose qw( Str HashRef ArrayRef Bool ); 
use File::Spec::Functions qw( catdir splitpath rel2abs );
require File::Remove;
require File::Basename;

our $VERSION = '1.100';
$VERSION = eval { return $VERSION };

with 'Perl::Dist::WiX::Role::Asset';

has name => (
	is       => 'ro',
	isa      => Str,
	reader   => '_get_name',
	required => 1,
);

has license => (
	is       => 'ro',
	isa      => HashRef,
	reader   => '_get_license',
	required => 1,
);

has patch => (
	is       => 'ro',
	isa      => ArrayRef,
	reader   => '_get_patch',
	required => 1,
);

has unpack_to => (
	is       => 'ro',
	isa      => Str,
	reader   => '_get_unpack_to',
	default => q{},
);

has install_to => (
	is       => 'ro',
	isa      => Str,
	reader   => '_get_install_to',
	required => 1,
);

has force => (
	is       => 'ro',
	isa      => Bool,
	reader   => '_get_force',
	lazy     => 1,
	default  => sub { $_[0]->parent->force ? 1 : 0 },
);

has toolchain => (
	is       => 'ro',
	isa      => 'Perl::Dist::Util::Toolchain',
	reader   => '_get_toolchain',
	required => 1,
);

sub install {
	my $self = shift;

	$self->_trace_line( 0, 'Preparing ' . $self->_get_name . "\n" );

	my $fl2 = File::List::Object->new->readdir(
		catdir( $self->_get_image_dir, 'perl' ) );

	# Download the file
	my $tgz = $self->_mirror( $self->_get_url, $self->_get_download_dir, );

	# Unpack to the build directory
	my $unpack_to = catdir( $self->_get_build_dir, $self->_get_unpack_to );
	if ( -d $unpack_to ) {
		$self->_trace_line( 2, "Removing previous $unpack_to\n" );
		File::Remove::remove( \1, $unpack_to );
	}
	my @files = $self->_extract( $tgz, $unpack_to );

	# Get the versioned name of the directory
	( my $perlsrc = $tgz ) =~ s{\.tar\.gz\z | \.tgz\z}{}msx;
	$perlsrc = File::Basename::basename($perlsrc);

	# Pre-copy updated files over the top of the source
	my $patch = $self->_get_patch;
	my $version = $self->_get_version;
	if ($patch) {

		# Overwrite the appropriate files
		foreach my $file ( @{$patch} ) {
			$self->_patch_file( "perl-$version/$file" => $unpack_to );
		}
	}

	# Copy in licenses
	if ( ref $self->_get_license eq 'HASH' ) {
		my $license_dir = catdir( $self->_get_image_dir, 'licenses' );
		$self->_extract_filemap( $tgz, $self->_get_license, $license_dir, 1 );
	}

	# Build win32 perl
  SCOPE: {
		my $wd = $self->_pushd( $unpack_to, $perlsrc, 'win32' );

		# Prepare to patch
		my $image_dir = $self->_get_image_dir;
		my $INST_TOP = catdir( $image_dir, $self->_get_install_to );
		my ($INST_DRV) = splitpath( $INST_TOP, 1 );

		$self->_trace_line( 2, "Patching makefile.mk\n" );
		$self->_patch_file(
			"perl-$version/win32/makefile.mk" => $unpack_to,
			{   dist     => $self->_get_parent(),
				INST_DRV => $INST_DRV,
				INST_TOP => $INST_TOP,
			} );

		$self->_trace_line( 1, "Building perl $version...\n" );
		$self->_make;

		my $long_build =
		  Win32::GetLongPathName( rel2abs( $self->_get_build_dir ) );

		my $force = $self->_get_force();
		if ( ( not $force ) && ( $long_build =~ /\s/ms ) && ($self->_get_version eq '5.10.0')) {
			$force = 1;
			$self->_trace_line( 0, <<"EOF");
***********************************************************
* Perl 5.10.0 cannot be tested at this point.
* Because the build directory
* $long_build
* contains spaces when it becomes a long name,
* testing the CPANPLUS module fails in 
* lib/CPANPLUS/t/15_CPANPLUS-Shell.t
* 
* You may wish to build perl within a directory
* that does not contain spaces by setting the build_dir
* (or temp_dir, which sets the build_dir indirectly if
* build_dir is not specified) parameter to new to a 
* directory that does not contain spaces.
*
* -- csjewell\@cpan.org
***********************************************************
EOF
		} ## end if ( ( not $perl->force...))
		
		unless ( $force ) {
			local $ENV{PERL_SKIP_TTY_TEST} = 1;
			$self->_trace_line( 1, "Testing perl...\n" );
			$self->_make('test');
		}

		$self->_trace_line( 1, "Installing perl...\n" );
		$self->_make(qw/install UNINST=1/);
	} ## end SCOPE:

	my $fl_lic = File::List::Object->new()->readdir(
		catdir( $self->_get_image_dir, 'licenses', 'perl' ) );
	$self->_insert_fragment( 'perl_licenses', $fl_lic );

	my $fl = File::List::Object->new()->readdir(
		catdir( $self->_get_image_dir, 'perl' ) );
	$fl->subtract($fl2)->filter( $self->_filters );
	$self->_insert_fragment( 'perl', $fl );

	# Upgrade the toolchain modules
	$self->install_perl_toolchain();

	return 1;
}

=head2 install_perl_toolchain

The C<install_perl_toolchain> method is a routine provided to install the
"perl toolchain": the modules required for CPAN (and CPANPLUS on 5.10.x 
versions of perl) to be able to install modules.

Returns true (technically, the object that called it), or throws an exception.

=cut

sub install_perl_toolchain {
	my $self = shift;
	my $toolchain = $self->_get_toolchain();

	my ( $core, $module_id );

	# Install the toolchain dists
	foreach my $dist ( @{ $toolchain->{dists} } ) {
		my $automated_testing = 0;
		my $release_testing   = 0;
		my $force             = $self->_get_force;
		if ( $dist =~ /Scalar-List-Util/msx ) {

			# Does something weird with tainting
			$force = 1;
		}
		if ( $dist =~ /URI-/msx ) {

			# Can't rely on t/heuristic.t not finding a www.perl.bv
			# because some ISP's use DNS redirectors for unfindable
			# sites.
			$force = 1;
		}
		if ( $dist =~ /Term-ReadLine-Perl/msx ) {

			# Does evil things when testing, and
			# so testing cannot be automated.
			$automated_testing = 1;
		}
		if ( $dist =~ /TermReadKey-2\.30/msx ) {

			# Upgrading to this version, instead...
			$dist = 'STSI/TermReadKey-2.30.01.tar.gz';
		}
		if ( $dist =~ /CPAN-1\.9402/msx ) {

			# 1.9402 fails its tests... ANDK says it's a test bug.
			$force = 1;
		}
		if ( $dist =~ /ExtUtils-ParseXS-2\.20(?:02)?\.tar\.gz/msx ) {

			# 2.20 and 2.2002 are buggy on 5.8.9.
			$dist = 'DAGOLDEN/ExtUtils-ParseXS-2.20_05.tar.gz'
		}

		$module_id = $self->_name_to_module($dist);
		$core =
		  exists $Module::CoreList::version{ $self->perl_version_literal }
		  {$module_id} ? 1 : 0;
#<<<
		$self->install_distribution(
			name              => $dist,
			mod_name          => $self->_module_fix($module_id),
			force             => $force,
			automated_testing => $automated_testing,
			release_testing   => $release_testing,
			$core
			  ? (
				  makefilepl_param => ['INSTALLDIRS=perl'],
				  buildpl_param => ['--installdirs', 'core'],
				)
			  : (),
		);
#>>>
	} ## end foreach my $dist ( @{ $toolchain...})

	return $self;
} ## end sub install_perl_toolchain


1;
