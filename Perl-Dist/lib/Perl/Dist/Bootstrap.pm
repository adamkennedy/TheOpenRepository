package Perl::Dist::Bootstrap;

use 5.006;
use strict;
use warnings;
use base 'Perl::Dist::Vanilla';
use File::Remove ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.01';
}





#####################################################################
# Constructor

# Apply some default paths
sub new {
	shift->SUPER::new(
		app_id               => 'bootperl',
		app_name             => 'Bootstrap Perl',
		image_dir            => 'C:\\bootperl',
		@_,
	);
}

# Lazily default the full name
sub app_ver_name {
	$_[0]->{app_ver_name} or
	$_[0]->app_name . ' ' . $_[0]->perl_version_human;
}

# Lazily default the file name
sub output_base_filename {
	$_[0]->{output_base_filename} or
	'bootstrap-perl-' . $_[0]->perl_version_human;
}





#####################################################################
# Installation Methods

sub install_perl_5100_bin {
	my $self = shift;
	$self->SUPER::install_perl_5100_bin(@_);

	$self->install_file(
		share      => 'Perl-Dist vanilla/CPAN_Config.pm',
		install_to => 'perl/lib/CPAN/Config.pm',
	);

	return 1;
}

sub install_perl_5100_toolchain_object {
	Perl::Dist::Util::Toolchain->new(
		perl_version => $_[0]->perl_version_literal,
		force        => {
			'ExtUtils::CBuilder' => 'KWILLIAMS/ExtUtils-CBuilder-0.21.tar.gz',
		},
	);
}

# Install various additional modules
sub install_perl_modules {
	my $self = shift;

	# Install the basics
	$self->install_module(
		name => 'Bundle::LWP',
	);

	# Install various developer tools
	#$self->install_module(
	#	name => 'Bundle::CPAN',
	#);
	$self->install_module(
		name => 'pler',
	);
	$self->install_module(
		name => 'PAR::Dist',
	);
	$self->install_module(
		name => 'DBI',
	);

	# Install SQLite
	$self->install_distribution(
		name  => 'MSERGEANT/DBD-SQLite-1.14.tar.gz',
		force => 1,
	);

	# Now we have SQLite, install the CPAN::SQLite upgrade
	$self->install_module(
		name => 'CPAN::SQLite',
	);

	return 1;
}

1;

__END__

=pod

=head1 NAME

Perl::Dist::Bootstrap - A bootstrap Perl for building Perl distributions

=head1 DESCRIPTION

"Bootstrap Perl" is a Perl distribution, and a member of the
"Vanilla Perl" series of distributions.

The L<Perl::Dist::Bootstrap> module can be used in conjunction wit the
L<perldist> command line tool to create a bootstrap Perl distribution.

Most of the time nobody will be using
Perl::Dist::Bootstrap directly, but will be downloading the pre-built
installer for Bootstrap Perl from the Vanilla Perl website at
L<http://vanillaperl.com/>.

=head2 Why Is This Needed?

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

Bootstrap Perl must be installed in C:\bootstrap.  The
executable installer adds the following environment variable changes:

    * adds directories to PATH
        - C:\bootstrap\perl\bin
        - C:\bootstrap\c\bin

    * adds directories to LIB
        - C:\bootstrap\c\lib
        - C:\bootstrap\perl\bin

    * adds directories to INCLUDE 
        - C:\bootstrap\c\include
        - C:\bootstrap\perl\lib\CORE

LIB and INCLUDE changes are likely more than are necessary, but attempt to
head off potential problems compiling external programs for use with Perl.

The "cpan" program is pre-configured with a known-good setup, but you may
wish to reconfigure it.

Manual CPAN configuration may be repeated by running the following command:

    perl -MCPAN::FirstTime -e "CPAN::FirstTime::init"

=head1 SUPPORT

Bootstrap Perl discussion is centered at L<http://win32.perl.org/>.

Other venues for discussion may be listed there.

Please report bugs or feature requests using the CPAN Request Tracker.
Bugs can be sent by email to C<<< bug-Perl-Dist-Bootstrap@rt.cpan.org >>> or
submitted using the web interface at
L<http://rt.cpan.org/Dist/Display.html?Queue=Perl-Dist-Bootstrap>

=head1 AUTHOR

Adam Kennedy <adamk@cpan.org>

=head1 COPYRIGHT

Copyright 2007 - 2008 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
