package Perl::Dist::Vanilla;

use 5.006;
use strict;
use warnings;
use base 'Perl::Dist';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '16';
}





#####################################################################
# Upstream Binary Packages

my %PACKAGES = (
	# Disabled as the generate test failures in 5.10.0
	# 'mingw-runtime' => 'mingw-runtime-3.14.tar.gz',
	# 'w32api'        => 'w32api-3.11.tar.gz',
);

sub binary_file {
	$PACKAGES{$_[1]} or
	shift->SUPER::binary_file(@_);
}





#####################################################################
# Configuration

# Apply some default paths
sub new {
	my $class = shift;

	# Prepend defaults
	my $self = $class->SUPER::new(
		app_id            => 'vanillaperl',
		app_name          => 'Vanilla Perl',
		app_publisher     => 'Vanilla Perl Project',
		app_publisher_url => 'http://vanillaperl.org/',
		image_dir         => 'C:\\vanilla',

		# Always generate both forms
		exe               => 1,
		zip               => 1,
		@_,
	);

	return $self;
}

# Lazily default the full name
sub app_ver_name {
	$_[0]->{app_ver_name} or
	$_[0]->app_name . ' ' . $_[0]->perl_version_human . ' ' . $_[0]->VERSION;
}

# Lazily default the file name
sub output_base_filename {
	$_[0]->{output_base_filename} or
	'vanilla-perl-' . $_[0]->perl_version_human . '-build-' . $_[0]->VERSION;
}





#####################################################################
# Installation Script

sub install_perl_5100_bin {
	my $self  = shift;
	$self->SUPER::install_perl_5100_bin(@_);

	# Overwrite the CPAN config to be relocatable
	$self->install_file(
		share      => 'Perl-Dist vanilla/Config5100.pm',
		install_to => 'perl/lib/Config.pm',
	);
	$self->install_file(
		share      => 'Perl-Dist vanilla/Config_heavy5100.pl',
		install_to => 'perl/lib/Config_heavy.pl',
	);
	$self->install_file(
		share      => 'Perl-Dist vanilla/CPAN_Config.pm',
		install_to => 'perl/lib/CPAN/Config.pm',
	);

	return 1;
}

sub install_perl_modules {
	my $self = shift;
	$self->SUPER::install_perl_modules(@_);

	$self->install_module(
		name  => 'Win32::File',
		force => 1,
	);
	$self->install_module(
		name => 'Win32::API',
	);

	# We want expat as well
	$self->install_expat;

	# Install XML::Parser
	$self->install_distribution(
		name             => 'MSERGEANT/XML-Parser-2.36.tar.gz',
		makefilepl_param => [
			'EXPATLIBPATH=' . File::Spec->catdir(
				$self->image_dir, 'c', 'lib',
			),
			'EXPATINCPATH=' . File::Spec->catdir(
				$self->image_dir, 'c', 'include',
			),
		],
	);

	return 1;
}

1;

__END__

=pod

=head1 NAME

Perl::Dist::Vanilla - Vanilla Perl for Win32

=head1 DESCRIPTION

Vanilla Perl is an experimental Perl distribution for the Microsoft Windows
platform that includes a bundled compiler.  Vanilla Perl provides a
Win32 installation of Perl that is as close as possible to the core Perl
distrubution, while offering the ability to install XS CPAN modules directly
from CPAN.  Vanilla Perl aims to include only the smallest possible changes
from the Perl core necessary to achieve this goal.

Vanilla Perl includes:

=over

=item *

Perl 5.10.0

=item *

Mingw GCC C/C++ compiler

=item *

Dmake "make" tool

=back

Vanilla Perl is intended for use by automated testing systems and master-level
Perl developers.  The primary anticipated uses for Vanilla Perl include
examining Win32-related issues in the Perl core, and for working on fixing
complex dependency and Win32 platform bugs in CPAN modules.  

Vanilla Perl serves as the basis more user-centric Win32 Perl distributions
that include incremental bundled capabilities for general application
development or application deployment needs.

Vanilla Perl is strongly not recommended for general use on Win32 platforms
for any purpose other than detecting and fixing bugs in Vanilla Perl
and testing Win32 compatibility of various CPAN modules.

Vanilla Perl will undergo changes without notice over time in an attempt to
intentionally provoke errors and uncover problems close to the Perl core, so
users should expect that it may unexpectedly display strange behaviours and
various other problems.

See L</"DOWNLOADING THE INSTALLER"> for instructions on where to download and
how to install Vanilla Perl.  

See L<Perl::Dist::Inno> at L<http://search.cpan.org> for details on 
the builder used to create Vanilla Perl from source.

=head1 CHANGES FROM CORE PERL

Vanilla Perl is and will continue to be based on the latest "stable" release
of Perl, currently version 5.10.0.

For the 5.10.0 series, no additional modules are installed.

A stub CPAN Config.pm file is installed.  It provides defaults to the path
for dmake, to automatically follow dependencies and some other tweaks to
allow for a smoother CPAN usage.

=head1 DOWNLOADING THE INSTALLER

Vanilla Perl Builds from 4 on are available from L<http://vanillaperl.com/>.

Earlier builds of Vanilla Perl are available on Sourceforge.net as part of the
Camelpack project: L<http://camelpack.sourceforge.net/>

=head1 CONFIGURATION

At present, the installation criteria for Vanilla Perl are quite strict.

We hope to address some of these issues during the 5.10.1 timeline to
make things a bit more flexible.

Sorry :(

Vanilla cannot co-exist with any other Perl installations at this time.

Vanilla cannot co-exist with Cygwin.

You should remove any other Perl installations before installing Vanilla Perl.

Vanilla Perl must be installed in C:\vanilla.

Once installed, you should add to the following environment variables.

    * add directories to PATH
        - C:\vanilla\c\bin
        - C:\vanilla\perl\bin 

    * add directories to LIB
        - C:\vanilla\c\lib
        - C:\vanilla\perl\bin

    * add directories to INCLUDE 
        - C:\vanilla\c\include 
        - C:\vanilla\perl\lib\CORE 

LIB and INCLUDE changes are likely more than are necessary, but attempt to
head off potential problems compiling external programs for use with Perl
and various CPAN modules.

The "cpan" program is pre-configured with a known-good setup, but you may
wish to reconfigure it.

Manual CPAN configuration may be repeated by running the following command:

    perl -MCPAN::FirstTime -e "CPAN::FirstTime::init"

=head1 CONTACTS AND BUGS REPORTING

Currently, Vanilla Perl discussion is centered at L<http://win32.perl.org>.
New venues for discussion may be listed there.

Please report bugs or feature requests using the CPAN Request Tracker.
Bugs can be sent by email to C<<< bug-Perl-Dist-Vanilla@rt.cpan.org >>> or
submitted using the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Perl-Dist-Vanilla>

=head1 LICENSE AND COPYRIGHT

Vanilla Perl is open source and may be licensed under the same terms as Perl.
Open source software included with Vanilla Perl installations are governed by
their respective licenses.  See LICENSE.txt for details.

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
