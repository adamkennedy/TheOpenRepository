package Perl::Dist::Vanilla;

use 5.005;
use strict;
use base 'Perl::Dist';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '12';
}





#####################################################################
# Configuration

sub app_name             { 'Vanilla Perl'                       }
sub app_ver_name         { "Vanilla Perl 5.10.0 $VERSION"       }
sub app_publisher        { 'Vanilla Perl Project'               }
sub app_publisher_url    { 'http://vanillaperl.org/'            }
sub app_id               { 'vanillaperl'                        }
sub output_base_filename { "vanilla-perl-5.10.0-build-$VERSION" }

# Apply some default paths
sub new {
	shift->SUPER::new(
		image_dir => 'C:\\vanilla',
		temp_dir  => 'C:\\tmp\\vp',
		@_,
	);
}





#####################################################################
# Installation Script

# Vanilla never has any additional libraries.
# Just install the C toolchain and Perl core.
sub run {
	my $self = shift;

	# Install the C toolchain
	my $t1 = time;
	$self->install_c_toolchain;
	$self->trace("Completed install_c_toolchain in " . (time - $t1) . " seconds\n");

	# Install the Perl 5.10.0 binary
	my $t2 = time;
	$self->install_perl_5100;
	$self->trace("Complete install_perl_5110 in " . (time - $t2) . " seconds\n");

	# Write out the zip
	my $t3  = time;
	$self->remove_waste;
	my $exe = $self->write_exe;
	$self->trace("Completed write_exe in " . (time - $t3) . " seconds\n");

	# Finished
	$self->trace("Distribution exe file created as $exe\n");
	return 1;
}

sub install_perl_5110 {
	my $self = shift;
	$self->SUPER::install_perl(@_);

	# Install the vanilla CPAN::Config
	$self->install_file(
		share      => 'Perl-Dist vanilla/CPAN_Config.pm',
		install_to => 'perl/lib/CPAN/Config.pm',
	);

	return 1;
}

1;

__END__

=head1 NAME

Perl::Dist::Vanilla - Vanilla Perl for win32

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

Vanilla Perl will eventually serve as the basis for additional Win32 Perl
distributions that include incremental bundled capabilities for general
application development or application deployment needs.

Vanilla Perl is strongly not recommended for general use on Win32 platforms at
this time for any purpose other than detecting and fixing bugs in Vanilla Perl
and testing Win32 compatibility of various CPAN modules.

Vanilla Perl will undergo changes without notice over time in an attempt to
intentionally provoke errors and uncover problems close to the Perl core, so
users should expect that it may unexpectedly display strange behaviours and
various other problems.

The Perl::Dist::Vanilla distribution on CPAN contains scripts and instructions
for downloading component sources and assembling them into the executable
installer for Vanilla Perl.  It B<does not> include the resulting Vanilla Perl
installation itself.  

See L</"DOWNLOADING THE INSTALLER"> for instructions on where to download and
how to install Vanilla Perl.  

See L<Perl::Dist::Build> at L<http://search.cpan.org> for details on 
the builder used to create Vanilla Perl from source.

=head1 CHANGES FROM CORE PERL

Vanilla Perl is and will continue to be based on the latest "stable" release
of Perl, currently version 5.10.0.

For the 5.10.0 series, no additional modules are installed.

A stub CPAN Config.pm file is installed.  It provides defaults to the path
for dmake, to automatically follow dependencies and to use the Windows
temporary directory for the CPAN working directory.

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

You should remove any other Perl installations before installing Vanilla Perl.

Vanilla Perl must be installed in C:\vanilla.

Vanilla Perl 5.10.0 Build 9 comes in .zip format. Availability of an
.exe installer has regressed while .exe creation undergoes a rewrite.

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

The first time that the "cpan" program is run, users will be prompted for
configuration settings. You can go with the defaults if you wish, although
since Vanilla is for experts only, you should probably configure manually.

Manual CPAN configuration may be repeated by running the following command:

    perl -MCPAN::FirstTime -e "CPAN::FirstTime::init"

=head1 CONTACTS AND BUGS REPORTING

Currently, Vanilla Perl discussion is centered at win32.perl.org.  New 
venues for discussion may be listed there.

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
