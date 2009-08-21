package Perl::Dist::WiX::Libraries;

=pod

=head1 NAME

Perl::Dist::WiX::Libraries - Library installation routines

=head1 VERSION

This document describes Perl::Dist::WiX::Libraries version 1.100.

=head1 DESCRIPTION

This module provides the routines that Perl::Dist::WiX uses in order to
install the C toolchain and library files.  

=head1 SYNOPSIS

	# This module is not to be used independently.

=head1 INTERFACE

=cut

use 5.008001;
use strict;
use warnings;
use File::Spec::Functions qw( catfile );
use Perl::Dist::WiX::Exceptions;

our $VERSION = '1.100';
$VERSION = eval { return $VERSION };

#####################################################################
# Installing C Toolchain and Library Packages

=pod

=head2 install_dmake

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
		PDWiX->throw(q{Can't execute make});
	}

	$self->insert_fragment( 'dmake', $filelist );

	return 1;
} ## end sub install_dmake

=pod

=head2 install_gcc

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

	$self->insert_fragment( 'gcc_core', $fl );

	$fl = $self->install_binary( name => 'gcc-g++', );

	$self->insert_fragment( 'gcc_gplusplus', $fl );

	return 1;
} ## end sub install_gcc

=pod

=head2 install_binutils

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
		PDWiX->throw(q{Can't execute dlltool});
	}

	$self->insert_fragment( 'binutils', $filelist );

	return 1;
} ## end sub install_binutils

=pod

=head2 install_pexports

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
		url        => $self->binary_url('pexports-0.43-1.zip'),
		license    => { 'pexports-0.43/COPYING' => 'pexports/COPYING', },
		install_to => { 'pexports-0.43/bin' => 'c/bin', },
	);
	$self->{bin_pexports} =
	  catfile( $self->image_dir, 'c', 'bin', 'pexports.exe' );
	unless ( -x $self->bin_pexports ) {
		PDWiX->throw(q{Can't execute pexports});
	}

	$self->insert_fragment( 'pexports', $filelist );

	return 1;
} ## end sub install_pexports

=pod

=head2 install_mingw_runtime

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

	$self->insert_fragment( 'mingw_runtime', $filelist );

	return 1;
} ## end sub install_mingw_runtime

=pod

=head2 install_zlib

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

	my $filelist = $self->install_binary(
		name      => 'zlib',
		install_to => q{.},
		url       => $self->binary_url('libzlib-1.2.3-bin_20090819.zip'),
	);

	$self->insert_fragment( 'zlib', $filelist );

	return 1;
} ## end sub install_zlib

=pod

=head2 install_win32api

  $dist->install_win32api

The C<install_win32api> method installs C<MinGW win32api> layer, to
allow C code to compile against native Win32 APIs.

Returns true or throws an exception on error.

=cut

sub install_win32api {
	my $self = shift;

	my $filelist = $self->install_binary( name => 'w32api', );

	$self->insert_fragment( 'w32api', $filelist );

	return 1;
}

=pod

=head2 install_mingw_make

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

	$self->insert_fragment( 'mingw_make', $filelist );

	return 1;
}

=pod

=head2 install_libiconv

  $dist->install_libiconv

The C<install_libiconv> method installs the C<GNU libiconv> library,
which is used for various character encoding tasks, and is needed for
other libraries such as C<libxml>.

Returns true or throws an exception on error.

=cut

sub install_libiconv {
	my $self     = shift;

	my $filelist = $self->install_binary( name => 'libiconv', );

	# The dll is installed with a different name than what our
	# prebuilt libxml2.dll expects, so we copy it to the
	# expected name post-install.
#	my $from = catfile( $self->image_dir, 'c', 'bin', 'libiconv2.dll' );
#	my $to   = catfile( $self->image_dir, 'c', 'bin', 'iconv.dll' );
#	$self->_copy( $from, $to );
#	$filelist->add_file($to);

	$self->insert_fragment( 'libiconv', $filelist );

	return 1;
} ## end sub install_libiconv

=pod

=head2 install_libxml

  $dist->install_libxml

The C<install_libxml> method installs the C<Gnome libxml> library,
which is a fast, reliable, XML parsing library, and the new standard
library for XML parsing.

Returns true or throws an exception on error.

=cut

sub install_libxml {
	my $self = shift;

	my $filelist = $self->install_binary(
		name       => 'libxml2',
		install_to => q{.},
		url        => $self->binary_url('libxml2-2.7.3-bin_20090819.zip'),
	);

	$self->insert_fragment( 'libxml', $filelist );

	return 1;
} ## end sub install_libxml

=pod

=head2 install_expat

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

	$self->insert_fragment( 'libexpat', $filelist );

	return 1;
} ## end sub install_expat

=pod

=head2 install_gmp

  $dist->install_gmp

The C<install_gmp> method installs the C<GNU Multiple Precision Arithmetic
Library>, which is used for fast and robust bignum support.

Returns true or throws an exception on error.

=cut

sub install_gmp {
	my $self = shift;

	# Comes as a single prepackaged vanilla-specific zip file
	my $filelist = $self->install_binary( name => 'gmp', );

	$self->insert_fragment( 'gmp', $filelist );

	return 1;
}

=pod

=head2 install_six

  $dist->install_six

The C<install_six> method installs (via a ZIP file) an experimental parrot
and rakudo conglomeration codenamed "six" that is utterly unlike whatever
the final packaged binary of Perl 6 will look like.

This method should only be called after all Perl 5 components are installed.

=cut

sub install_six {
	my $self = shift;

	# Install Gabor's crazy Perl 6 blob
	my $filelist = $self->install_binary(
		name       => 'six',
		install_to => q{.}
	);
	$self->insert_fragment( 'six', $filelist );
	$self->add_env_path('six');

	return 1;
} ## end sub install_six

__END__

=pod

=head1 DIAGNOSTICS

See L<Perl::Dist::WiX::Diagnostics|Perl::Dist::WiX::Diagnostics> for a list of
exceptions that this module can throw.

=head1 BUGS AND LIMITATIONS (SUPPORT)

Bugs should be reported via: 

1) The CPAN bug tracker at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Dist-WiX>
if you have an account there.

2) Email to E<lt>bug-Perl-Dist-WiX@rt.cpan.orgE<gt> if you do not.

For other issues, contact the topmost author.

=head1 AUTHORS

Curtis Jewell E<lt>csjewell@cpan.orgE<gt>

=head1 SEE ALSO

L<Perl::Dist|Perl::Dist>, L<Perl::Dist::WiX|Perl::Dist::WiX>, 
L<http://ali.as/>, L<http://csjewell.comyr.com/perl/>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 Curtis Jewell.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this distribution.

=cut
