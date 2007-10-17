package Perl::Dist::Vanilla;
$VERSION = '7'; # build number

use strict;
use warnings;

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

Perl 5.8.8

=item *

Mingw GCC C/C++ compiler

=item *

Dmake "make" tool

=item *

Select CPAN modules

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
of Perl, currently version 5.8.8.  Some additional modifications are included
that improve general compatibility with the Win32 platform or improve
"turnkey" operation on Win32.  

Whenever possible, these modifications will be made only by preinstalling
additional CPAN modules within Vanilla Perl, particularly modules that have
been newly included as core Perl modules in the "development" branch of perl
(aka "bleadperl") to address Win32 compatibility issues.

Modules or distributions currently included are:

=over

=item * 

Win32API::File -- to allow for deletion of in-use files at next reboot;
required for CPAN.pm to be able to upgrade itself

=item *

IO -- to address Win32 Socket bugs
    
=item *

Compress::Zlib, IO::Zlib and Archive::Tar -- to eliminate the CPAN.pm
dependency on external, binary programs to handle .tar.gz files

=item *

Archive::Zip (and its dependency, Time::Local) -- to eliminate the CPAN.pm
dependency on external, binary programs to handle .zip files

=item *

libnet -- provides Net::FTP to eliminate the CPAN.pm dependency on an external,
binary ftp program; installed configured for FTP passive mode

=back

Additionally, a stub CPAN Config.pm file is installed.  It provides defaults
to the path for dmake, to automatically follow dependencies and to use the
Windows temporary directory for the CPAN working directory. 

=head1 DOWNLOADING THE INSTALLER

Vanilla Perl Builds from 4 on are available from L<http://vanillaperl.com/>.

Earlier builds of Vanilla Perl are available on Sourceforge.net as part of the
Camelpack project: L<http://camelpack.sourceforge.net/>

=head1 CONFIGURATION

At present, Vanilla Perl must be installed in C:\vanilla-perl.  The executable
installer adds the following environment variable changes:

    * adds directories to PATH
        - C:\vanilla-perl\dmake\bin
        - C:\vanilla-perl\mingw\bin
        - C:\vanilla-perl\perl\bin 

    * adds directories to LIB
        - C:\vanilla-perl\mingw\lib
        - C:\vanilla-perl\perl\bin

    * adds directories to INCLUDE 
        - C:\vanilla-perl\mingw\include 
        - C:\vanilla-perl\perl\lib\CORE 
        - C:\vanilla-perl\perl\lib\encode

LIB and INCLUDE changes are likely more than are necessary, but attempt to
head off potential problems compiling external programs for use with Perl.

Users installing Vanilla Perl manually without the installer will need to
change their environment variables manually.

The first time that the "cpan" program is run, users will be prompted for
configuration settings.  With the defaults provided in Vanilla Perl, users may
answer "no" to manual configuration and the installation should still work.

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
