package Perl::Dist::WiX::BuildPerl::5142;

=pod

=begin readme text

Perl::Dist::WiX::BuildPerl::5142 version 1.0

=end readme

=for readme stop

=head1 NAME

Perl::Dist::WiX::BuildPerl::5142 - Files and code for building Perl 5.14.2

=head1 VERSION

This document describes Perl::Dist::WiX::BuildPerl::5142 version 1.0.

=begin readme

=head1 INSTALLATION

To install this module, run the following commands:

	perl Build.PL
	./Build
	./Build test
	./Build install

=end readme

=for readme stop

=head1 DESCRIPTION

This module provides the routines and files that Perl::Dist::WiX uses in 
order to build Perl 5.14.2 itself.  

=head1 SYNOPSIS

	# This module is not to be used independently.
	# It provides methods to be called on a Perl::Dist::WiX object.
	# See Perl::Dist::WiX::BuildPerl::PluginInterface for more information.

=cut

use 5.010;
use Moose::Role;
use File::ShareDir qw();
use Perl::Dist::WiX::Asset::Perl qw();

our $VERSION = '1.0';



around '_install_perl_plugin' => sub {
	shift;
	my $self = shift;

	# Check for an error in the object.
	if ( not $self->bin_make() ) {
		PDWiX->throw('Cannot build Perl yet, no bin_make defined');
	}

	# Install perl.
	my $perl = Perl::Dist::WiX::Asset::Perl->new(
		parent => $self,
		url    => 'http://search.cpan.org/CPAN/authors/id/F/FL/FLORA/perl-5.14.2.tar.gz', #FIX on version bump
		patch     => [ qw{
			  lib/CPAN/Config.pm
			  win32/config.gc
			  win32/config.gc64nox
			  win32/config_sh.PL
			  win32/config_H.gc
			  win32/config_H.gc64nox
                          win32/FindExt.pm
			  }
		],
		license => {
			'perl-5.14.2/Readme'   => 'perl/Readme',
			'perl-5.14.2/Artistic' => 'perl/Artistic',
			'perl-5.14.2/Copying'  => 'perl/Copying',
		},
	);
	$perl->install();

	return 1;
}; ## end sub install_perl_plugin



around '_build_toolchain_modules' => sub {
	shift;
	my $self = shift;

	#XXX-FIXME hack by kmx: removed ExtUtils::ParseXS from the list below
        my @modules_list = ( qw {
		  ExtUtils::MakeMaker
		  File::Path
		  ExtUtils::Command
		  Win32API::File
		  ExtUtils::Install
		  ExtUtils::Manifest
		  Test::Harness
		  Test::Simple
		  ExtUtils::CBuilder		  
		  version
		  Scalar::Util
		  Compress::Raw::Zlib
		  Compress::Raw::Bzip2
		  IO::Compress::Base
		  Compress::Bzip2
		  IO::Zlib
		  File::Spec
		  File::Temp
		  Win32::WinError
		  Win32API::Registry
		  Win32::TieRegistry
		  IPC::Run3
		  Probe::Perl
		  Test::Script
		  File::Which
		  File::HomeDir
		  Archive::Zip
		  Package::Constants
		  IO::String
		  Archive::Tar
		  Compress::unLZMA
	} );

	push @modules_list, qw{
	  Win32::UTCFileTime
	  CPAN::Meta::YAML
	  JSON::PP
	  Parse::CPAN::Meta
	  YAML
	  Net::FTP
	  Digest::MD5
	  Digest::SHA1
	  Digest::SHA
	  Module::Metadata
	  Perl::OSType
	  Version::Requirements
	  CPAN::Meta
	  Module::Build
	  Term::Cap
	  CPAN
	  Term::ReadKey
	  Term::ReadLine::Perl
	  Text::Glob
	  Data::Dumper
	  Pod::Text
	  URI

	  HTML::Tagset
	  HTML::Parser
	  WWW::RobotRules
	  HTTP::Cookies
	  Net::HTTP
	  HTTP::Daemon
	  HTTP::Negotiate
	  File::Listing
	  HTML::Parser
	  HTTP::Date
	  HTTP::Status
	  Encode::Locale
	  LWP::MediaTypes
	  URI::Escape
	  LWP

	  File::Slurp
	  Capture::Tiny
	};

=for cmt
list LWP dependencies for a new version
Old version should be used because support of https in new version depeds on Net::SSLeay
which does not work on 64-bit Perl (https://rt.cpan.org/Public/Bug/Display.html?id=53585)
	 qw{
	  Encode::Locale
	  File::Listing
	  HTTP::Date
	  URI
	  HTML::Tagset
	  HTML::Parser
	  LWP::MediaTypes
	  HTTP::Message
	  HTTP::Cookies
	  HTTP::Negotiate
	  Net::HTTP
	  WWW::RobotRules
	  LWP::UserAgent
	};
=cut

	return \@modules_list;
};

around '_get_forced_toolchain_dists' => sub {
	return {};
};


around '_build_library_information' => sub {
	my $orig = shift;
	my $self = shift;
	my $originals = $self->$orig();
	my $libraries;
	
	if (32 == $self->bits()) {
		$libraries = {
			%{$originals},
			'dmake'         => 'kmx/32_tools/32bit_dmake-SVN20091127-bin_20100308.zip',
			'mingw-make'    => 'kmx/32_tools/32bit_gmake-3.82-bin_20110503.zip',
			'pexports'      => 'kmx/32_tools/32bit_pexports-0.44-bin_20100110.zip',
			'patch'         => 'kmx/32_tools/32bit_patch-2.5.9-7-bin_20100110_UAC.zip',
			'gcc-toolchain' => 'kmx/32_gcctoolchain/mingw64-w32-gcc4.4.7-pre_20111101.zip',
			'gcc-license'   => 'kmx/32_gcctoolchain/mingw64-w32-gcc4.4.7-pre_20111101-lic.zip',			
			'libdb'		=> 'kmx/32_libs/5.14/32bit_db-5.1.25-bin_20110506.zip',
			'libexpat'	=> 'kmx/32_libs/5.14/32bit_expat-2.0.1-sezero20110428-bin_20110506.zip',
			'freeglut'	=> 'kmx/32_libs/5.14/32bit_freeglut-2.6.0-bin_20110506.zip',
			'libfreetype'	=> 'kmx/32_libs/5.14/32bit_freetype-2.4.4-bin_20110506.zip',
			'libgd'		=> 'kmx/32_libs/5.14/32bit_gd-2.0.35(OLD-jpg-png)-bin_20110506.zip',
			'libgdbm'	=> 'kmx/32_libs/5.14/32bit_gdbm-1.8.3-bin_20110506.zip',
			'libgif'	=> 'kmx/32_libs/5.14/32bit_giflib-4.1.6-bin_20110506.zip',
			'gmp'		=> 'kmx/32_libs/5.14/32bit_gmp-5.0.1-bin_20110506.zip',
			'libjpeg'	=> 'kmx/32_libs/5.14/32bit_jpeg-8c-bin_20110506.zip',
			'libxpm'	=> 'kmx/32_libs/5.14/32bit_libXpm-3.5.9-bin_20110506.zip',
			'libiconv'	=> 'kmx/32_libs/5.14/32bit_libiconv-1.13.1-sezero20110428-bin_20110506.zip',
			'libpng'	=> 'kmx/32_libs/5.14/32bit_libpng-1.5.2-bin_20110506.zip',
			'libssh2'	=> 'kmx/32_libs/5.14/32bit_libssh2-1.2.8-bin_20110506.zip',
			'libxml2'	=> 'kmx/32_libs/5.14/32bit_libxml2-2.7.8-bin_20110506.zip',
			'libxslt'	=> 'kmx/32_libs/5.14/32bit_libxslt-1.1.26-bin_20110506.zip',
			'mpc'		=> 'kmx/32_libs/5.14/32bit_mpc-0.9-bin_20110506.zip',
			'mpfr'		=> 'kmx/32_libs/5.14/32bit_mpfr-3.0.1-bin_20110506.zip',
			'libmysql'	=> 'kmx/32_libs/5.14/32bit_mysql-5.1.44-bin_20100304.zip',
			'libopenssl'	=> 'kmx/32_libs/5.14/32bit_openssl-1.0.0d-bin_20110506.zip',
			'libpostgresql'	=> 'kmx/32_libs/5.14/32bit_postgresql-9.0.4-bin_20110506.zip',
			'libtiff'	=> 'kmx/32_libs/5.14/32bit_tiff-3.9.5-bin_20110506.zip',
			'libxz'		=> 'kmx/32_libs/5.14/32bit_xz-5.0.2-bin_20110506.zip',
			'zlib'		=> 'kmx/32_libs/5.14/32bit_zlib-1.2.5-bin_20110506.zip',		};
	} else { # 64-bit.
		$libraries = {
			%{$originals},
			'dmake'         => 'kmx/64_tools/64bit_dmake-SVN20091127-bin_20100308.zip',
			'mingw-make'    => 'kmx/64_tools/64bit_gmake-3.82-bin_20110503.zip',
			'pexports'      => 'kmx/64_tools/64bit_pexports-0.44-bin_20100110.zip',
			'patch'         => 'kmx/64_tools/64bit_patch-2.5.9-7-bin_20100110_UAC.zip',
			'gcc-toolchain' => 'kmx/64_gcctoolchain/mingw64-w64-gcc4.4.7-pre_20111101.zip',
			'gcc-license'   => 'kmx/64_gcctoolchain/mingw64-w64-gcc4.4.7-pre_20111101-lic.zip',
			'libdb'		=> 'kmx/64_libs/5.14/64bit_db-5.1.25-bin_20110506.zip',
			'libexpat'	=> 'kmx/64_libs/5.14/64bit_expat-2.0.1-sezero20110428-bin_20110506.zip',
			'freeglut'	=> 'kmx/64_libs/5.14/64bit_freeglut-2.6.0-bin_20110506.zip',
			'libfreetype'	=> 'kmx/64_libs/5.14/64bit_freetype-2.4.4-bin_20110506.zip',
			'libgd'		=> 'kmx/64_libs/5.14/64bit_gd-2.0.35(OLD-jpg-png)-bin_20110506.zip',
			'libgdbm'	=> 'kmx/64_libs/5.14/64bit_gdbm-1.8.3-bin_20110506.zip',
			'libgif'	=> 'kmx/64_libs/5.14/64bit_giflib-4.1.6-bin_20110506.zip',
			'gmp'		=> 'kmx/64_libs/5.14/64bit_gmp-5.0.1-bin_20110506.zip',
			'libjpeg'	=> 'kmx/64_libs/5.14/64bit_jpeg-8c-bin_20110506.zip',
			'libxpm'	=> 'kmx/64_libs/5.14/64bit_libXpm-3.5.9-bin_20110506.zip',
			'libiconv'	=> 'kmx/64_libs/5.14/64bit_libiconv-1.13.1-sezero20110428-bin_20110506.zip',
			'libpng'	=> 'kmx/64_libs/5.14/64bit_libpng-1.5.2-bin_20110506.zip',
			'libssh2'	=> 'kmx/64_libs/5.14/64bit_libssh2-1.2.8-bin_20110506.zip',
			'libxml2'	=> 'kmx/64_libs/5.14/64bit_libxml2-2.7.8-bin_20110506.zip',
			'libxslt'	=> 'kmx/64_libs/5.14/64bit_libxslt-1.1.26-bin_20110506.zip',
			'mpc'		=> 'kmx/64_libs/5.14/64bit_mpc-0.9-bin_20110506.zip',
			'mpfr'		=> 'kmx/64_libs/5.14/64bit_mpfr-3.0.1-bin_20110506.zip',
			'libmysql'	=> 'kmx/64_libs/5.14/64bit_mysql-5.1.44-bin_20100304.zip',
			'libopenssl'	=> 'kmx/64_libs/5.14/64bit_openssl-1.0.0d-bin_20110506.zip',
			'libpostgresql'	=> 'kmx/64_libs/5.14/64bit_postgresql-9.0.4-bin_20110506.zip',
			'libtiff'	=> 'kmx/64_libs/5.14/64bit_tiff-3.9.5-bin_20110506.zip',
			'libxz'		=> 'kmx/64_libs/5.14/64bit_xz-5.0.2-bin_20110506.zip',
			'zlib'		=> 'kmx/64_libs/5.14/64bit_zlib-1.2.5-bin_20110506.zip',		};
	}
	
	return $libraries;
};



around 'library_directory' => sub {
	shift;
	my $self = shift;
	
	return $self->bits() . 'bit-gcc44';
};



around '_find_perl_file' => sub {
	my $orig = shift;
	my $self = shift;
	my $file = shift;

	my $location = undef;

	$location = eval {
		File::ShareDir::module_file( 'Perl::Dist::WiX::BuildPerl::5142', #FIX on version bump
			"default/$file" );
	};

	if ($location) {
		return $location;
	} else {
		return $self->$orig($file);
	}
};

# Set the things that are defined by the perl version.

has 'perl_version_literal' => (
	is       => 'ro',
	init_arg => undef,
	default  => '5.014002', #FIX on version bump
);

has 'perl_version_human' => (
	is       => 'ro',
	writer   => '_set_perl_version_human',
	init_arg => undef,
	default  => '5.14.2', #FIX on version bump
);

has '_perl_version_arrayref' => (
	is       => 'ro',
	init_arg => undef,
	default  => sub { [ 5, 14, 2 ] }, #FIX on version bump
);

has '_perl_bincompat_version_arrayref' => (
	is       => 'ro',
	init_arg => undef,
	default  => sub { [ 5, 13, 31 ] }, #FIX on version bump
        # for perl version 5.M.N is [ 5, (M-1), 32 ] 
        # example: [ 5, 13, 31 ] turns into Upgrade.VersionMax = 5.13.31999
        # related to VersionMax which is reported to have maximum 127.254.32767
);

has '_is_git_snapshot' => (
	is       => 'ro',
	init_arg => undef,
	default  => q{},
);

has 'required_module_corelist' => (
	is       => 'ro',
	init_arg => undef,
	default  => sub { '2.49' },
);

no Moose::Role;
1;

__END__

=pod

=head1 DIAGNOSTICS

This module does not throw exceptions.

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

L<Perl::Dist::WiX|Perl::Dist::WiX>, 
L<http://ali.as/>, L<http://csjewell.comyr.com/perl/>

=for readme continue

=head1 COPYRIGHT AND LICENSE

Copyright 2009 - 2011 Curtis Jewell.

Copyright 2008 - 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this distribution.

=for readme stop

=cut
