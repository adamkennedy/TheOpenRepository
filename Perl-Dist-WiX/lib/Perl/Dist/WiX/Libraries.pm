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
use Params::Util qw( _STRING );
use Perl::Dist::WiX::Exceptions;
use Readonly;

our $VERSION = '1.100_001';
$VERSION =~ s/_//;

Readonly my %PACKAGES => (
	'32bit-gcc3' => {
		'dmake'         => 'dmake-4.8-20070327-SHAY.zip',
		'mingw-make'    => 'mingw32-make-3.81-2.tar.gz',
		'pexports'      => 'pexports-0.43-1.zip',
		'gcc-toolchain' => 'mingw32-gcc3-toolchain-20091026-subset.tar.gz',
# Former components of what's now included in gcc-toolchain.
#		'gcc-core'      => 'gcc-core-3.4.5-20060117-3.tar.gz',
#		'gcc-g++'       => 'gcc-g++-3.4.5-20060117-3.tar.gz',
#		'binutils'      => 'binutils-2.17.50-20060824-1.tar.gz',
#		'mingw-runtime' => 'mingw-runtime-3.13.tar.gz',
#		'w32api'        => 'w32api-3.10.tar.gz',
	},
	'32bit-gcc4' => {
		'dmake'         => 'dmake-4.8-20070327-SHAY.zip',
		'mingw-make'    => 'mingw32-make-3.81-2.tar.gz',
		'pexports'      => 'pexports-0.43-1.zip',
		'gcc-toolchain' => 'mingw-w32-20091019_subset.7z',
	},
	'64bit-gcc4' => {
		'dmake'         => 'dmake-4.8-20070327-SHAY.zip',
		'mingw-make'    => 'mingw32-make-3.81-2.tar.gz',
		'pexports'      => 'pexports-0.43-1.zip',
		'gcc-toolchain' => 'mingw-w32-20091019_subset.7z',
	},
);

sub _binary_file {
	my $self = shift;
	my $package = shift;
	
	my $toolchain = $self->bits() . 'bit-gcc' . $self->gcc_version();	
	
	$self->trace_line(3, "Searching for $package in $toolchain\n");
	
	if (not exists $PACKAGES{$toolchain}) {
		PDWiX->throw('Can only build 32 or 64-bit versions of perl');
	}
	
	if (not exists $PACKAGES{$toolchain}{$package}) {
		PDWiX->throw('get_package_file was called on a package that was not defined.');
	}	

	my $package_file = $PACKAGES{$toolchain}{$package};
	$self->trace_line(3, "Pachage $package is in $package_file\n");

	return $package_file;
}

sub _binary_url {
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
		$file = $self->_binary_file( $file, @_ );
	}
	return $self->binary_root . q{/} . $file;
} ## end sub binary_url



#####################################################################
# Installing C Toolchain and Library Packages

=pod

=head2 install_gcc_toolchain

  $dist->install_gcc_toolchain

The C<install_dmake> method installs the corrent gcc toolchain into the
distribution, and is typically installed during "C toolchain" build
phase.

It provides the approproate arguments to C<install_binary> and then
validates that the binary was installed correctly.

Returns true or throws an exception on error.

=cut

sub install_gcc_toolchain {
	my $self = shift;

	# Install the gcc toolchain
	my $filelist = $self->install_binary(
		name    => 'gcc-toolchain',
		url     => $self->_binary_url('gcc-toolchain'),
		license => {
			'COPYING'     => 'gcc/COPYING',
			'COPYING.lib' => 'gcc/COPYING.lib',
		},
	);

	$self->insert_fragment( 'gcc-toolchain', $filelist );

	return 1;
} ## end sub install_dmake

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
		url     => $self->_binary_url('dmake'),
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
		url        => $self->_binary_url('pexports'),
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

	my $filelist = $self->install_binary( 
		name => 'mingw-make', 
		url  => $self->_binary_url('mingw-make'),
	);

	$self->insert_fragment( 'mingw_make', $filelist );

	return 1;
}

1;

__END__

# =pod

# =head2 install_gcc

  # $dist->install_gcc

# The C<install_gcc> method installs the B<GNU C Compiler> into the
# distribution, and is typically installed during "C toolchain" build
# phase.

# It provides the appropriate arguments to several C<install_binary>
# calls. The default C<install_gcc> method installs two binary
# packages, the core compiler 'gcc-core' and the C++ compiler 'gcc-c++'.

# Returns true or throws an exception on error.

# =cut

sub install_gcc {
	my $self = shift;

	# Install the compilers (gcc)
	my $fl = $self->install_binary(
		name    => 'gcc-core',
		url     => $self->_binary_url('gcc-core'),
		license => {
			'COPYING'     => 'gcc/COPYING',
			'COPYING.lib' => 'gcc/COPYING.lib',
			'doc/mingw-runtime/Contributors' => 'mingw/Contributors',
			'doc/mingw-runtime/Disclaimer'   => 'mingw/Disclaimer',
		},
	);

	$self->insert_fragment( 'gcc_core', $fl );

	$fl = $self->install_binary( 
		name => 'gcc-g++', 
		url  => $self->_binary_url('gcc-g++'),
	);

	$self->insert_fragment( 'gcc_gplusplus', $fl );

	return 1;
} ## end sub install_gcc

# =pod

# =head2 install_binutils

  # $dist->install_binutils

# The C<install_binutils> method installs the C<GNU binutils> package into
# the distribution.

# The most important of these is C<dlltool.exe>, which is used to extract
# static library files from .dll files. This is needed by some libraries
# to let the Perl interfaces build against them correctly.

# Returns true or throws an exception on error.

# =cut

sub install_binutils {
	my $self = shift;

	my $filelist = $self->install_binary(
		name    => 'binutils',
		url     => $self->_binary_url('binutils'),
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

# =pod

# =head2 install_mingw_runtime

  # $dist->install_mingw_runtime

# The C<install_mingw_runtime> method installs the MinGW runtime package
# into the distribution, which is basically the MinGW version of libc and
# some other very low level libs.

# Returns true or throws an exception on error.

# =cut

sub install_mingw_runtime {
	my $self = shift;

	my $filelist = $self->install_binary(
		name    => 'mingw-runtime',
		url     => $self->_binary_url('mingw-runtime'),
		license => {
			'doc/mingw-runtime/Contributors' => 'mingw/Contributors',
			'doc/mingw-runtime/Disclaimer'   => 'mingw/Disclaimer',
		},
	);

	$self->insert_fragment( 'mingw_runtime', $filelist );

	return 1;
} ## end sub install_mingw_runtime

# =pod

# =head2 install_win32api

  # $dist->install_win32api

# The C<install_win32api> method installs C<MinGW win32api> layer, to
# allow C code to compile against native Win32 APIs.

# Returns true or throws an exception on error.

# =cut

sub install_win32api {
	my $self = shift;

	my $filelist = $self->install_binary( 
		name => 'w32api',
		url  => $self->_binary_url('w32api'),
	);

	$self->insert_fragment( 'w32api', $filelist );

	return 1;
}

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
