package Test::Perl::Dist;

use strict;
use warnings;
use 5.008001;
use Test::More 0.88 import => ['!done_testing'];
use parent qw( Exporter );
use English qw( -no_match_vars );
use Scalar::Util qw( blessed );
use LWP::Online qw( :skip_all );
use File::Spec::Functions qw( :ALL );
use File::Path qw();
use File::Remove qw();
use Win32 qw();
use URI qw();

our @EXPORT =
  qw(test_run_dist test_add test_verify_files_short test_verify_files_medium  test_verify_files_long test_verify_portability );
push @EXPORT, @Test::More::EXPORT;

BEGIN {
	our $VERSION = '0.200';
	$VERSION = eval $VERSION; ##no critic(RequireConstantVersion)

	if ( $OSNAME ne 'MSWin32' ) {
		plan( skip_all => 'Not on Win32' );
	}
	if ( rel2abs( curdir() ) =~ m{[.]}ms ) {
		plan( skip_all =>
			  'Cannot be tested in a directory with an extension.' );
	}
} ## end BEGIN

my $tests_completed = 0;



#####################################################################
# Default Paths

sub _make_path {
	my $dir = rel2abs( catdir( curdir(), @_ ) );
	File::Path::mkpath($dir) unless -d $dir;
	ok( -d $dir, 'Created ' . $dir );
	$tests_completed++;
	return $dir;
}

sub _remake_path {
	my $dir = rel2abs( catdir( curdir(), @_ ) );
	File::Remove::remove( \1, $dir ) if -d $dir;
	File::Path::mkpath($dir);
	ok( -d $dir, 'Created ' . $dir );
	$tests_completed++;
	return $dir;
}

sub _paths {
	my $class = shift;
	my $subpath = shift || q{};

 # Create base and download directory so we can do a GetShortPathName on it.
	my $basedir  = rel2abs( catdir( 't', "tmp$subpath" ) );
	my $download = rel2abs( catdir( 't', 'download' ) );

	if ( $basedir =~ m{\s}sm ) {
		plan( skip_all =>
			  'Cannot test successfully in a test directory with spaces' );
	}

	File::Path::mkpath($basedir)  unless -d $basedir;
	File::Path::mkpath($download) unless -d $download;
	$basedir  = Win32::GetShortPathName($basedir);
	$download = Win32::GetShortPathName($download);
	diag("Test base directory: $basedir");

	# Make or remake the subpaths
	my $output_dir = _remake_path( catdir( $basedir, 'output' ) );
	my $image_dir  = _remake_path( catdir( $basedir, 'image' ) );
	my $download_dir = _make_path($download);
	my $fragment_dir = _remake_path( catdir( $basedir, 'fragments' ) );
	my $build_dir    = _remake_path( catdir( $basedir, 'build' ) );
	return (
		output_dir   => $output_dir,
		image_dir    => $image_dir,
		download_dir => $download_dir,
		build_dir    => $build_dir,
		fragment_dir => $fragment_dir,
	);
} ## end sub _paths

sub _cpan_release {
	my $class = shift;
	if ( defined $ENV{PERL_RELEASE_TEST_PERLDIST_CPAN} ) {
		return (
			cpan => URI->new( $ENV{PERL_RELEASE_TEST_PERLDIST_CPAN} ) );
	} else {
		return ();
	}
}

sub _cpan {
	if ( $ENV{PERL_TEST_PERLDIST_CPAN} ) {
		return URI->new( $ENV{PERL_TEST_PERLDIST_CPAN} );
	}
	my $path = rel2abs( catdir( 't', 'data', 'cpan' ) );
	Test::More::ok( -d $path, 'Found CPAN directory' );
	Test::More::ok( -d catdir( $path, 'authors', 'id' ),
		'Found id subdirectory' );
	$tests_completed += 2;
	return URI::file->new( $path . q{\\} );
}

sub new_test_class_short {
	my $self          = shift;
	my $test_number   = shift;
	my $test_version  = shift;
	my $class_to_test = shift;
	my $test_class =
	  $self->create_test_class_short( $test_number, $test_version,
		$class_to_test );
	my $test_object = eval {
		my $obj = $test_class->new( $self->_paths($test_number),
			$self->_cpan_release, @_ );
		return $obj;
	};
	if ($EVAL_ERROR) {
		if ( blessed($EVAL_ERROR)
			&& $EVAL_ERROR->isa('Exception::Class::Base') )
		{
			diag( $EVAL_ERROR->as_string );
		} else {
			diag($EVAL_ERROR);
		}

		# Time to get out.
		BAIL_OUT('Error in test object creation.');
	} ## end if ($EVAL_ERROR)

	isa_ok( $test_object, $class_to_test );
	$tests_completed++;

	return $test_object;
} ## end sub new_test_class_short

sub new_test_class_medium {
	my $self          = shift;
	my $test_number   = shift;
	my $test_version  = shift;
	my $class_to_test = shift;

	if ( not $ENV{RELEASE_TESTING} ) {
		plan( skip_all => 'No RELEASE_TESTING: Skipping very long test' );
	}

	my $test_class =
	  $self->create_test_class_medium( $test_number, $test_version,
		$class_to_test );
	my $test_object = eval {
		$test_class->new( $self->_paths($test_number),
			$self->_cpan_release, @_ );
	};

	if ($EVAL_ERROR) {
		if ( blessed($EVAL_ERROR)
			&& $EVAL_ERROR->isa('Exception::Class::Base') )
		{
			diag( $EVAL_ERROR->as_string );
		} else {
			diag($EVAL_ERROR);
		}

		# Time to get out.
		BAIL_OUT('Error in test object creation.');
	} ## end if ($EVAL_ERROR)

	isa_ok( $test_object, $class_to_test );
	$tests_completed++;

	return $test_object;
} ## end sub new_test_class_medium

sub new_test_class_long {
	my $self          = shift;
	my $test_number   = shift;
	my $test_version  = shift;
	my $class_to_test = shift;

	if ( not $ENV{RELEASE_TESTING} ) {
		plan( skip_all => 'No RELEASE_TESTING: Skipping very long test' );
	}

	my $test_class =
	  $self->create_test_class_long( $test_number, $test_version,
		$class_to_test );
	my $test_object = eval {
		$test_class->new( $self->_paths($test_number),
			$self->_cpan_release, @_ );
	};

	if ($EVAL_ERROR) {
		if ( blessed($EVAL_ERROR)
			&& $EVAL_ERROR->isa('Exception::Class::Base') )
		{
			diag( $EVAL_ERROR->as_string );
		} else {
			diag($EVAL_ERROR);
		}

		# Time to get out.
		BAIL_OUT('Error in test object creation.');
	} ## end if ($EVAL_ERROR)

	isa_ok( $test_object, $class_to_test );
	$tests_completed++;

	return $test_object;
} ## end sub new_test_class_long

sub test_run_dist {
	my $dist = shift;

	# Run the dist object, and ensure everything we expect was created
	my $time  = scalar localtime;
	my $class = ref $dist;
	if ( $class !~ m/::Short/msx ) {
		diag("Building test dist @ $time.");
		if ( $class =~ m/::Long/msx ) {
			diag('Building may take several hours... (sorry)');
		} else {
			diag('Building may take an hour or two... (sorry)');
		}
	}
	ok( eval { $dist->run; 1; }, '->run ok' );
	if ($EVAL_ERROR) {
		if ( blessed($EVAL_ERROR)
			&& $EVAL_ERROR->isa('Exception::Class::Base') )
		{
			diag( $EVAL_ERROR->as_string );
		} else {
			diag($EVAL_ERROR);
		}
		BAIL_OUT('Could not run test object.');
	}
	$time = scalar localtime;
	if ( $class !~ m/::Short/msx ) {
		diag("Test dist finished @ $time.");
	}
	$tests_completed++;

	return;
} ## end sub test_run_dist

sub test_add {
	$tests_completed++;

	return;
}

sub test_verify_files_short {
	my $test_number = shift;
	my $test_dir = catdir( 't', "tmp$test_number", qw{ image c bin } );

	ok( -f catfile( $test_dir, qw{ dmake.exe } ), 'Found dmake.exe' );

	ok( -f catfile( $test_dir, qw{ startup Makefile.in } ),
		'Found startup' );

	$tests_completed += 2;

	return;
} ## end sub test_verify_files_short

sub test_verify_files_medium {
	my $test_number = shift;
	my $dll_version = shift;

	my $dll_file = "perl${dll_version}.dll";
	my $test_dir = catdir( 't', "tmp$test_number", 'image' );

	# C toolchain files
	ok( -f catfile( $test_dir, qw{ c bin dmake.exe } ), 'Found dmake.exe',
	);
	ok( -f catfile( $test_dir, qw{ c bin startup Makefile.in } ),
		'Found startup',
	);
	ok( -f catfile( $test_dir, qw{ c bin pexports.exe } ),
		'Found pexports',
	);

	# Perl core files
	ok( -f catfile( $test_dir, qw{ perl bin perl.exe } ),
		'Found perl.exe',
	);

	# Toolchain files
	ok( -f catfile( $test_dir, qw{ perl vendor lib LWP.pm } ),
		'Found LWP.pm', );

	# Custom installed file
	ok( -f catfile( $test_dir, qw{ perl vendor lib Config Tiny.pm } ),
		'Found Config::Tiny',
	);

	# Did we build 5.8.8?
	ok( -f catfile( $test_dir, qw{ perl bin }, $dll_file ),
		'Found Perl DLL',
	);

	$tests_completed += 7;

	return;
} ## end sub test_verify_files_medium

sub create_test_class_short {
	my $self         = shift;
	my $test_number  = shift;
	my $test_version = shift;
	my $test_class   = shift;
	my $answer       = "Test::Perl::Dist::Short$test_number";

	my $code = <<"EOF";
		require $test_class;

		\@${answer}::ISA = ( "$test_class" );

		###############################################################
		# Configuration

		sub ${answer}::app_name             { 'Test Perl'               }
		sub ${answer}::app_ver_name         { 'Test Perl 1 alpha 1'     }
		sub ${answer}::app_publisher        { 'Vanilla Perl Project'    }
		sub ${answer}::app_publisher_url    { 'http://vanillaperl.org'  }
		sub ${answer}::app_id               { 'testperl'                }

		###############################################################
		# Main Methods

		sub ${answer}::new {
			return shift->${test_class}::new(
				perl_version => $test_version,
				trace        => 1,
				build_number => 1,
				tasklist     => [qw(final_initialization install_dmake)],
				\@_,
			);
		}
EOF

	eval $code;
	return $answer;
} ## end sub create_test_class_short

sub create_test_class_medium {
	my $self         = shift;
	my $test_number  = shift;
	my $test_version = shift;
	my $test_class   = shift;
	my $answer       = "Test::Perl::Dist::Medium$test_number";

	eval <<"EOF";
		require $test_class;

		\@${answer}::ISA = ( "$test_class" );

		###############################################################
		# Configuration

		sub ${answer}::app_name             { 'Test Perl'               }
		sub ${answer}::app_ver_name         { 'Test Perl 1 alpha 1'     }
		sub ${answer}::app_publisher        { 'Vanilla Perl Project'    }
		sub ${answer}::app_publisher_url    { 'http://vanillaperl.org'  }
		sub ${answer}::app_id               { 'testperl'                }

		###############################################################
		# Main Methods

		sub ${answer}::new {
			return shift->${test_class}::new(
				perl_version => $test_version,
				trace => 1,
				build_number => 1,
				tasklist => [ qw(
					final_initialization
					install_c_toolchain
					install_c_libraries
					install_perl
					test_distro
					regenerate_fragments
					write
				)],
				\@_,
			);
		}

		sub ${answer}::test_distro {
			my \$self = shift;
			\$self->install_distribution(
				name =>     'ADAMK/Config-Tiny-2.12.tar.gz',
				mod_name => 'Config::Tiny',
			);		
			return 1;
		}
EOF

	return $answer;
} ## end sub create_test_class_medium

sub create_test_class_long {
	my $self         = shift;
	my $test_number  = shift;
	my $test_version = shift;
	my $test_class   = shift;
	my $answer       = "Test::Perl::Dist::Long$test_number";

	eval <<"EOF";

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

		###############################################################
		# Main Methods

		sub new {
			return shift->SUPER::new(
				perl_version => $test_version,
				trace => 1,
				build_number => 1,
				\@_,
			);
		}
EOF

	return $answer;
} ## end sub create_test_class_long

sub test_verify_files_long {
	my $test_number = shift;
	my $dll_version = shift;

	my $dll_file = "perl${dll_version}.dll";
	my $test_dir = catdir( 't', "tmp$test_number", 'image' );

	# C toolchain files
	ok( -f catfile( $test_dir, qw{ c bin dmake.exe } ), 'Found dmake.exe',
	);
	ok( -f catfile( $test_dir, qw{ c bin startup Makefile.in } ),
		'Found startup',
	);
	ok( -f catfile( $test_dir, qw{ c bin pexports.exe } ),
		'Found pexports',
	);

	# Perl core files
	ok( -f catfile( $test_dir, qw{ perl bin perl.exe } ),
		'Found perl.exe',
	);

	# Toolchain files
	ok( -f catfile( $test_dir, qw{ perl vendor lib LWP.pm } ),
		'Found LWP.pm', );

	# Custom installed file
	ok( -f catfile( $test_dir, qw{ perl vendor lib Config Tiny.pm } ),
		'Found Config::Tiny',
	);

	# Did we build Perl correctly?
	ok( -f catfile( $test_dir, qw{ perl bin }, $dll_file ),
		'Found Perl DLL',
	);

	$tests_completed += 8;

	return;
} ## end sub test_verify_files_long

sub test_verify_portability {
	my $test_number = shift;

	my $test_dir = catdir( 't', "tmp$test_number" );

	# Did we build the zip file?
	ok( -f catfile( $test_dir, qw{ output test-perl-5.x.x-alpha-1.zip } ),
		'Found zip file',
	);

	# Did we build it portable?
	ok( -f catfile( $test_dir, qw{ image portable.perl } ),
		'Found portable file',
	);
	ok( -f catfile( $test_dir, qw{ image perl vendor lib Portable.pm } ),
		'Found Portable.pm',
	);

	$tests_completed += 3;

	return;
} ## end sub test_verify_portability

sub done_testing {
	my $additional_tests = shift || 0;

	return Test::More::done_testing( $tests_completed + $additional_tests );
}

1;

__END__

=pod

=begin readme text

Test::Perl::Dist version 0.200

=end readme

=for readme stop

=head1 NAME

Test::Perl::Dist - Test module for Perl::Dist::WiX and subclasses.

=head1 VERSION

This document describes Test::Perl::Dist version 0.200

=begin readme

=head1 INSTALLATION

To install this module, run the following commands:

	perl Makefile.PL
	make
	make test
	make install

This method of installation requires that a current version of Module::Build 
be installed.
    
Alternatively, to install with Module::Build, you can use the following commands:

	perl Build.PL
	./Build
	./Build test
	./Build install

=end readme

=for readme stop

=head1 SYNOPSIS

	TODO

=head1 DESCRIPTION

This module implements a test framework for Perl::Dist::WiX and subclasses 
of that module.

Using Test::More is not required, as this module re-exports all its functions.

=head1 INTERFACE 





=head1 DIAGNOSTICS

This module implements no diagnostics of its own, but reports .

=head1 CONFIGURATION AND ENVIRONMENT

There are no conficuration files.

=for readme continue

=head1 DEPENDENCIES

TODO

=for readme stop

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Bugs should be reported via: 

1) The CPAN bug tracker at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Perl-Dist>
if you have an account there.

2) Email to E<lt>bug-Test-Perl-Dist@rt.cpan.orgE<gt> if you do not.

=head1 AUTHOR

Curtis Jewell  C<< <CSJewell@cpan.org> >>

=for readme continue

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009, Curtis Jewell C<< <CSJewell@cpan.org> >>. 
All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself, either version
5.8.1 or any later version. See L<perlartistic> and L<perlgpl>.

The full text of the license can be found in the
LICENSE file included with this module.

=for readme stop

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
