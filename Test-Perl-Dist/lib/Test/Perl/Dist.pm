package Test::Perl::Dist;

use strict;
use 5.008001;
use Test::More 0.61;
use File::Spec::Functions qw( :ALL      );
use File::Path            qw(           );
use File::Remove          qw(           );
use Win32                 qw(           );
use URI                   qw(           );
use Scalar::Util          qw( blessed   );
use LWP::Online           qw( :skip_all );
use vars                  qw( $VERSION  );

BEGIN {
    use version; $VERSION = qv('0.192');

	unless ( $^O eq 'MSWin32' ) {
		plan( skip_all => 'Not on Win32' );
	};
	unless ( $ENV{RELEASE_TESTING} ) {
		plan( skip_all => 'No RELEASE_TESTING: Skipping very long test' );
	}
	if ( rel2abs( curdir() ) =~ m{\.} ) {
		plan( skip_all => 'Cannot be tested in a directory with an extension.' );
	}
}

my $tests_completed = 0;



#####################################################################
# Default Paths

sub make_path {
	my $dir = rel2abs( catdir( curdir(), @_ ) );
	File::Path::mkpath( $dir ) unless -d $dir;
	Test::More::ok( -d $dir, 'Created ' . $dir );
	$tests_completed++;
	return $dir;
}

sub remake_path {
	my $dir = rel2abs( catdir( curdir(), @_ ) );
	File::Remove::remove( \1, $dir ) if -d $dir;
	File::Path::mkpath( $dir );
	Test::More::ok( -d $dir, 'Created ' . $dir );
	$tests_completed++;
	return $dir;
}

sub paths {
	my $class        = shift;
	my $subpath      = shift || '';

	# Create base and download directory so we can do a GetShortPathName on it.
	my $basedir  = rel2abs( catdir( 't', "tmp$subpath" ) );
	my $download = rel2abs( catdir( 't', 'download' ) );

	if ( $basedir =~ m{\s} ) {
		plan( skip_all => 'Cannot test successfully in a test directory with spaces' );
	}

    File::Path::mkpath( $basedir )  unless -d $basedir;
	File::Path::mkpath( $download ) unless -d $download;
	$basedir  = Win32::GetShortPathName( $basedir );
	$download = Win32::GetShortPathName( $download );
	Test::More::diag($basedir);

	# Make or remake the subpaths
	my $output_dir   = remake_path( catdir( $basedir, 'output'    ) );
	my $image_dir    = remake_path( catdir( $basedir, 'image'     ) );
	my $download_dir =   make_path( $download                       );
	my $fragment_dir = remake_path( catdir( $basedir, 'fragments' ) );
	my $build_dir    = remake_path( catdir( $basedir, 'build'     ) );
	return (
		output_dir   => $output_dir,
		image_dir    => $image_dir,
		download_dir => $download_dir,
		build_dir    => $build_dir,
		fragment_dir => $fragment_dir,
	);
}

sub cpan_release {
	my $class = shift;
	if ( defined $ENV{RELEASE_TEST_PERLDIST_CPAN} ) {
		return ( cpan => URI->new($ENV{RELEASE_TEST_PERLDIST_CPAN}) );
	} else {
		return ();
	}
}

sub cpan {
	if ( $ENV{TEST_PERLDIST_CPAN} ) {
		return URI->new($ENV{TEST_PERLDIST_CPAN});
	}
	my $path = rel2abs( catdir( 't', 'data', 'cpan' ) );
	Test::More::ok( -d $path, 'Found CPAN directory' );
	Test::More::ok( -d catdir( $path, 'authors', 'id' ), 'Found id subdirectory' );
	$tests_completed += 2;
	return URI::file->new($path . '\\');
}

sub new1 {
	my $class = shift;
	return t::lib::TestQuick->new(
		$class->paths(@_),
		cpan => $class->cpan,
	);
}

sub new_test_class_medium {
	my $self = shift;
	my $test_number = shift;
	my $test_version = shift;
	my $class_to_test = shift;
	my $test_class = $self->create_test_class_medium($test_number, $test_version, $class_to_test);
	my $test_object = eval { $test_class->new( $self->paths($test_number), $self->cpan_release, @_ ) };
	if ( defined $@ ) {
		if ( blessed( $@ ) && $@->isa("Exception::Class::Base") ) {
			diag($@->as_string);
		} else {
			diag($@);
		}
		# Time to get out.
		BAIL_OUT('Could not create test object.');
	}

	isa_ok( $dist, $class_to_test );
	$tests_completed++;

	return $test_object;
}

sub new_test_class_long {
	my $self = shift;
	my $test_number = shift;
	my $test_version = shift;
	my $class_to_test = shift;
	my $test_class = $self->create_test_class_long($test_number, $test_version, $class_to_test);
	my $test_object = eval { $test_class->new( $self->paths($test_number), $self->cpan_release, @_ ) };
	if ( defined $@ ) {
		if ( blessed( $@ ) && $@->isa("Exception::Class::Base") ) {
			diag($@->as_string);
		} else {
			diag($@);
		}
		# Time to get out.
		BAIL_OUT('Could not create test object.');
	}

	isa_ok( $dist, $class_to_test );
	$tests_completed++;

	return $test_object;
}

sub test_run_dist {
	my $dist = shift;

	# Run the dist object, and ensure everything we expect was created
	my $time = scalar localtime();
	diag( "Building test dist @ $time." );
	diag( "Building may take several hours... (sorry)" );
	ok( eval { $dist->run; 1; }, '->run ok' );
	if ( defined $@ ) {
		if ( blessed( $@ ) && $@->isa("Exception::Class::Base") ) {
			diag($@->as_string);
		} else {
			diag($@);
		}
		BAIL_OUT('Could not run test object.');
	}
	$time = scalar localtime();
	diag( "Test dist finished @ $time." );
	$tests_completed++;

	return;
}

sub test_add {
	$tests_completed++;

	return;
}

sub test_verify_files_short {
	my $test_number = shift;
	my $test_dir = catdir('t', "tmp$test_number", qw{ image c bin }); 

	ok( 
		-f catfile( $test_dir, qw{ dmake.exe } ), 
		'Found dmake.exe'
	);

	ok( 
		-f catfile( $test_dir, qw{ startup Makefile.in } ), 
		'Found startup'
	);

	$tests_completed += 2;

	return;
}
	
sub test_verify_files_medium {
	my $test_number = shift;
	my $dll_version = shift;

	my $dll_file = "perl${dll_version}.dll";
	my $test_dir = catdir('t', "tmp$test_number", 'image'); 
	
	# C toolchain files
	ok(
		-f catfile( $test_dir, qw{ c bin dmake.exe } ),
		'Found dmake.exe',
	);
	ok(
		-f catfile( $test_dir, qw{ c bin startup Makefile.in } ),
		'Found startup',
	);
	ok(
		-f catfile( $test_dir, qw{ c bin pexports.exe } ),
		'Found pexports',
	);

	# Perl core files
	ok(
		-f catfile( $test_dir, qw{ perl bin perl.exe } ),
		'Found perl.exe',
	);

	# Toolchain files
	ok(
		-f catfile( $test_dir, qw{ perl site lib LWP.pm } ),
		'Found LWP.pm',
	);

	# Custom installed file
	ok(
		-f catfile( $test_dir, qw{ perl site lib Config Tiny.pm } ),
		'Found Config::Tiny',
	);

	# Did we build 5.8.8?
	ok(
		-f catfile( $test_dir, qw{ perl bin }, $dll_file ),
		'Found Perl DLL',
	);
	
	$tests_completed += 7;

	return;
}

sub create_test_class_short {
	my $self = shift;
	my $test_number = shift;
	my $test_version = shift;
	my $test_class = shift;
	my $answer = "Test::Perl::Dist::Short$test_number";

	eval {

		package $answer;

		use strict;
		require $test_class;

		use base $test_class;

		###############################################################
		# Configuration

		sub app_name             { 'Test Perl'               }
		sub app_ver_name         { 'Test Perl 1 alpha 1'     }
		sub app_publisher        { 'Vanilla Perl Project'    }
		sub app_publisher_url    { 'http://vanillaperl.org'  }
		sub app_id               { 'testperl'                }
		sub output_base_filename { 'test-perl-5.x.x-alpha-1' }

		###############################################################
		# Main Methods

		sub new {
			return shift->SUPER::new(
				perl_version => $test_version,
				trace => 101,
				build_number => 1,
				@_,
			);
		}

		sub run {
			my $self = shift;

			# Just install a single binary
			$self->checkpoint_task( install_dmake => 1 );

			return 1;
		}

	};

	return $answer;
}

sub create_test_class_medium {
	my $self = shift;
	my $test_number = shift;
	my $test_version = shift;
	my $test_class = shift;
	my $answer = "Test::Perl::Dist::Medium$test_number";

	eval {

		package $answer;

		use strict;
		require $test_class;

		use base $test_class;

		###############################################################
		# Configuration

		sub app_name             { 'Test Perl'               }
		sub app_ver_name         { 'Test Perl 1 alpha 1'     }
		sub app_publisher        { 'Vanilla Perl Project'    }
		sub app_publisher_url    { 'http://vanillaperl.org'  }
		sub app_id               { 'testperl'                }
		sub output_base_filename { 'test-perl-5.x.x-alpha-1' }

		###############################################################
		# Main Methods

		sub new {
			return shift->SUPER::new(
				perl_version => $test_version,
				trace => 101,
				build_number => 1,
				@_,
			);
		}

		sub run {
			my $self = shift;

			# Install the core binaries
			$self->install_c_toolchain;

			# Install the extra libraries
			$self->install_c_libraries;

			# Install Perl.
			$self->install_perl;

			# Install a test distro
			$self->install_distribution(
				name => 'ADAMK/Config-Tiny-2.12.tar.gz',
			);

			return 1;
		}

	};

	return $answer;
}

sub create_test_class_long {
	my $self = shift;
	my $test_number = shift;
	my $test_version = shift;
	my $test_class = shift;
	my $answer = "Test::Perl::Dist::Long$test_number";

	eval {

		package $answer;

		use strict;
		require $test_class;

		use base $test_class;

		###############################################################
		# Configuration

		sub app_name             { 'Test Perl'               }
		sub app_ver_name         { 'Test Perl 1 alpha 1'     }
		sub app_publisher        { 'Vanilla Perl Project'    }
		sub app_publisher_url    { 'http://vanillaperl.org'  }
		sub app_id               { 'testperl'                }
		sub output_base_filename { 'test-perl-5.x.x-alpha-1' }

		###############################################################
		# Main Methods

		sub new {
			return shift->SUPER::new(
				perl_version => $test_version,
				trace => 101,
				build_number => 1,
				@_,
			);
		}
	};

	return $answer;
}

sub test_verify_files_long {
	my $test_number = shift;
	my $dll_version = shift;

	my $dll_file = "perl${dll_version}.dll";
	my $test_dir = catdir('t', "tmp$test_number", 'image'); 
	
	# C toolchain files
	ok(
		-f catfile( $test_dir, qw{ c bin dmake.exe } ),
		'Found dmake.exe',
	);
	ok(
		-f catfile( $test_dir, qw{ c bin startup Makefile.in } ),
		'Found startup',
	);
	ok(
		-f catfile( $test_dir, qw{ c bin pexports.exe } ),
		'Found pexports',
	);

	# Perl core files
	ok(
		-f catfile( $test_dir, qw{ perl bin perl.exe } ),
		'Found perl.exe',
	);

	# Toolchain files
	ok(
		-f catfile( $test_dir, qw{ perl site lib LWP.pm } ),
		'Found LWP.pm',
	);

	# Custom installed file
	ok(
		-f catfile( $test_dir, qw{ perl site lib Config Tiny.pm } ),
		'Found Config::Tiny',
	);

	# Did we build Perl correctly?
	ok(
		-f catfile( $test_dir, qw{ perl bin }, $dll_file ),
		'Found Perl DLL',
	);
	
	$tests_completed += 8;

	return;
}

sub test_verify_portability {
	my $test_number = shift;

	my $test_dir = catdir('t', "tmp$test_number"); 
	
	# Did we build the zip file?
	ok(
		-f catfile( $test_dir, qw{ output test-perl-5.x.x-alpha-1.zip } ),
		'Found zip file',
	);

	# Did we build it portable?
	ok(
		-f catfile( $test_dir, qw{ image portable.perl } ),
		'Found portable file',
	);
	ok(
		-f catfile( $test_dir, qw{ image perl site lib Portable.pm } ),
		'Found Portable.pm',
	);

	$test_completed += 3;

	return;
}

1;
