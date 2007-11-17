package Perl::Dist::Bootstrap;

use 5.006;
use strict;
use base 'Perl::Dist';
use File::Remove ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}





#####################################################################
# Configuration

sub app_name             { 'Bootstrap Perl'               }
sub app_ver_name         { 'Bootstrap Perl Alpha 1'       }
sub app_publisher        { 'Vanilla Perl Project'         }
sub app_publisher_url    { 'http://vanillaperl.com/'      }
sub app_id               { 'bootstrapperl'                }
sub output_base_filename { 'bootstrap-perl-5.8.8-alpha-1' }





#####################################################################
# Constructor

# Apply some default paths
sub new {
	my $class = shift;
	return $class->SUPER::new(
		image_dir => 'C:\\bootperl',
		temp_dir  => 'C:\\tmp\\bp',
		@_,
	);
}

sub run {
	my $self = shift;

	# Install the main binaries
	my $t1 = time;
	$self->install_binaries;
	my $d1 = time - $t1;
	$self->trace("Completed install_binaries in $d1 seconds\n");

	# Install the additional C libs
	my $t6 = time;
	$self->install_libraries;
	my $d6 = time - $t6;
	$self->trace("Completed install_libraries in $d6 seconds\n");

	# Install Perl 5.8.8
	my $t2 = time;
	$self->install_perl;
	my $d2 = time - $t2;
	$self->trace("Completed install_perl in $d2 seconds\n");

	# Install the primary toolchain distributions
	my $t3 = time;
	$self->install_toolchain;
	my $d3 = time - $t3;
	$self->trace("Completed install_toolchain in $d3 seconds\n");

	# Install the additional modules
	my $t4 = time;
	$self->install_modules;
	my $d4 = time - $t4;
	$self->trace("Completed install_modules in $d4 seconds\n");

	# Write out the zip
	my $t5  = time;
	$self->remove_waste;
	my $iss = $self->write_iss;
	my $zip = $self->write_zip;
	my $d5  = time - $t5;
	$self->trace("Completed write in $d5 seconds\n");
	$self->trace("Inno-Setup Script created as $iss\n");
	$self->trace("Distribution zip file created as $zip\n");

	return 1;
}

my @TOOLCHAIN_DISTRIBUTIONS = qw{
	MSCHWERN/ExtUtils-MakeMaker-6.36.tar.gz
	DLAND/File-Path-2.02.tar.gz
	RKOBES/ExtUtils-Command-1.13.tar.gz
	YVES/Win32API-File-0.1001.tar.gz
 	MSCHWERN/ExtUtils-Install-1.44.tar.gz
	RKOBES/ExtUtils-Manifest-1.51.tar.gz
	PETDANCE/Test-Harness-2.64.tar.gz
	MSCHWERN/Test-Simple-0.72.tar.gz
	KWILLIAMS/ExtUtils-CBuilder-0.19.tar.gz
	KWILLIAMS/ExtUtils-ParseXS-2.18.tar.gz
	JPEACOCK/version-0.74.tar.gz
	GBARR/Scalar-List-Utils-1.19.tar.gz
	PMQS/IO-Compress-Base-2.006.tar.gz
	PMQS/Compress-Raw-Zlib-2.006.tar.gz
	PMQS/Compress-Raw-Bzip2-2.006.tar.gz
	PMQS/IO-Compress-Zlib-2.006.tar.gz
	PMQS/IO-Compress-Bzip2-2.006.tar.gz
	PMQS/Compress-Zlib-2.007.tar.gz
	ARJAY/Compress-Bzip2-2.09.tar.gz
	TOMHUGHES/IO-Zlib-1.07.tar.gz
	KWILLIAMS/PathTools-3.25.tar.gz
	TJENNESS/File-Temp-0.18.tar.gz
	BLM/Win32API-Registry-0.28.tar.gz
	ADAMK/Win32-TieRegistry-0.25.zip
	ADAMK/File-HomeDir-0.66.tar.gz
	PEREINAR/File-Which-0.05.tar.gz
	ADAMK/Archive-Zip-1.20.tar.gz
	KANE/Archive-Tar-1.36.tar.gz
	INGY/YAML-0.66.tar.gz
	GBARR/libnet-1.22.tar.gz
	GAAS/Digest-MD5-2.36.tar.gz
	GAAS/Digest-SHA1-2.11.tar.gz
	MSHELOR/Digest-SHA-5.45.tar.gz
	KWILLIAMS/Module-Build-0.2808.tar.gz
	JSTOWE/Term-Cap-1.11.tar.gz
	ANDK/CPAN-1.9203.tar.gz
};

sub install_toolchain {
	my $self = shift;

	foreach my $dist ( @TOOLCHAIN_DISTRIBUTIONS ) {
		$self->install_distribution(
			name => $dist,
		);
	}

	# Special install of Term::ReadLine::Perl, which does
	# evil things when testing
	$self->install_distribution(
		name              => 'ILYAZ/modules/Term-ReadLine-Perl-1.0302.tar.gz',
		automated_testing => 1,
	);

	# With the toolchain we need in place, install the default
	# configuation.
	$self->install_file(
		share      => 'Perl-Dist-Bootstrap CPAN_Config.pm',
		install_to => 'perl/lib/CPAN/Config.pm',
	);

	return 1;
}

sub install_modules {
	my $self = shift;

	# Install the companion Perl modules for the
	# various libs we installed.
	$self->install_module(
		name => 'XML::LibXML',
	);

	# Install the basics
	$self->install_module(
		name => 'Params::Util',
	);
	$self->install_module(
		name => 'Bundle::LWP',
	);

	# Install various developer tools
	$self->install_module(
		name => 'Bundle::CPAN',
	);
	$self->install_module(
		name => 'pler',
	);
	$self->install_module(
		name => 'pip',
	);
	$self->install_module(
		name => 'PAR::Dist',
	);

	# Install SQLite
	$self->install_module(
		name  => 'SQLite',
		force => 1,
	);

	return 1;
}

1;

__END__

=head1 NAME

Perl::Dist::Bootstrap - A bootstrap Perl for building Perl distributions

=head1 DESCRIPTION

"Bootstrap Perl" is a Perl distribution, and a member of the
"Vanilla Perl" series of distributions.

The Perl::Dist::Bootstrap module can be used to create a bootstrap
Perl distribution.

Most of the time nobody will be using
Perl::Dist::Bootstrap directly, but will be downloading the pre-built
installer for Bootstrap Perl from the Vanilla Perl website at
L<http://vanillaperl.com/>.

For people building Win32 Perl distributions based on L<Perl::Dist>,
one gotcha is that the distributions have hard-coded install paths.

As a result of this, it is not possible to use a distribution to build
a new/modified version of the same distribution.

To compensate for this, and make the process of building custom
distributions easier, this distribution has been created.

As an additional convenience, Bootstrap Perl comes with L<Perl::Dist>,
and several distribution subclasses (L<Perl::Dist::Vanilla>,
L<Perl::Dist::Strawberry> etc) already installed, as well as some
additional Perl development tools that might be useful during the
Perl distribution creation process.

=head2 CONFIGURATION

Bootstrap Perl must be installed in C:\strawberry-perl.  The
executable installer adds the following environment variable changes:

    * adds directories to PATH
        - C:\strawberry-perl\perl\bin
        - C:\strawberry-perl\dmake\bin
        - C:\strawberry-perl\c
        - C:\strawberry-perl\c\bin

    * adds directories to LIB
        - C:\strawberry-perl\c\lib
        - C:\strawberry-perl\perl\bin

    * adds directories to INCLUDE 
        - C:\strawberry-perl\c\include
        - C:\strawberry-perl\perl\lib\CORE
        - C:\strawberry-perl\perl\lib\encode

LIB and INCLUDE changes are likely more than are necessary, but attempt to
head off potential problems compiling external programs for use with Perl.

The first time that the "cpan" program is run, users will be prompted for
configuration settings.  With the defaults provided in Strawberry Perl, users
may answer "no" to manual configuration and the installation should still work.

Manual CPAN configuration may be repeated by running the following command:

    perl -MCPAN::FirstTime -e "CPAN::FirstTime::init"

=head1 SUPPORT

Vanilla Perl discussion is centered at L<http://win32.perl.org/>.

Other venues for discussion may be listed there.

Please report bugs or feature requests using the CPAN Request Tracker.
Bugs can be sent by email to C<<< bug-Perl-Dist-Bootstrap@rt.cpan.org >>> or
submitted using the web interface at
L<http://rt.cpan.org/Dist/Display.html?Queue=Perl-Dist-Bootstrap>

=head1 AUTHOR

Adam Kennedy <adamk@cpan.org>

=head1 COPYRIGHT

Copyright 2007 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
