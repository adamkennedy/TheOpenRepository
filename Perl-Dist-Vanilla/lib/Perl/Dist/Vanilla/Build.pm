package Perl::Dist::Vanilla::Build;
$VERSION = 4;
use strict;
use warnings;

1;
__END__

=head1 NAME

Perl::Dist::Vanilla::Build - Building Vanilla Perl from scratch

=head1 VERSION

This document refers to Vanilla Perl Build 4.

=head1 DESCRIPTION

The Perl::Dist::Vanilla distribution on CPAN contains scripts and instructions
for downloading component sources and assembling them into the executable
installer for Vanilla Perl.  It B<does not> include the resulting Vanilla Perl
installation itself.  

This document describes the build process for generating a Vanilla Perl
executable installer.  

As of Build 4, this documentation is incomplete.  Common build components will
be refactored into a separate package soon and docs will be revised more 
completely at that time.

=head1 PREREQUISITES

Perl::Dist::Vanilla requires an existing Win32 Perl installation to bootstrap
the installation process.  It also requires numerous modules for
the build scripts.  These modules are listed in the Perl::Dist::Vanilla 
META.yml.  Installing Perl::Dist::Vanilla will pick up all necessary
dependencies.

Perl::Dist::Vanilla also requires the free Inno Setup tool to create the 
executable installer.  Inno Setup can be downloaded from jrsoftware.org:

L<http://www.jrsoftware.org/isinfo.php>

=head1 BOOTSTRAPPING

Perl hard-codes @INC directories into the binary, making it difficult to
relocate on the fly.  As a result, Vanilla Perl needs to be built at 
C<< C:\vanilla-perl >>.  To use Perl::Dist::Vanilla, a separate perl
installation must be available on the same machine.  Here is one way of 
boostrapping to that point, assuming no Perl already exists on the
computer in question:

=over

=item *

Download a Vanilla Perl executable installer and install it.  It will be
located at C<< C:\vanilla-perl >>.  

=item *

Install the Perl::Dist::Vanilla tarball from CPAN to pick up all dependencies.

=item *

Download a separate copy of the Perl::Dist::Vanilla tarball to access the
programs and extra files for the build process.  Unpack it and open a
command shell in that directory.

=item *

Edit C<< vanilla.yml >> and change the "image_dir" parameter to a different
path, e.g. C<< C:\bootstrap-perl >> for this example.

=item *

Run C<< perl bin\full_build.pl >>, which will build and install a
Vanilla Perl installation at that location.  (See the next section for
details.)

=item *

Edit the PATH, LIB, and INCLUDE environment variables to refer to 
C<< bootstrap-perl >> instead of C<< vanilla-perl >>.

=item *

Install the Perl::Dist::Vanilla tarball from CPAN to pick up all dependencies
again, this time installed in the fresh C<< bootstrap-perl >>.

=item *

Change the C<< vanilla.yml >> image_dir parameter back to 
C<< C:\vanilla-perl >>.

=back

At this point, the perl located at C<< C:\bootstrap-perl >> will be the default
perl and will not be affected by rebuilding a new Vanilla Perl at 
C<< vanilla-perl >>.  

=head1 BUILDING THE INSTALLATION SOURCE DIRECTORY

From the Perl::Dist::Vanilla tarball directory, the C<< bin\full_build.pl >>
program will build a full Vanilla Perl installation, just as in the
bootstrap process.  This includes:

=over

=item *

Downloading binary packages for dmake and MinGW gcc and unpacking them
to the right locations.

=item *

Downloading Perl source, building it and installing it.

=item *

Downloading additional Perl modules from CPAN and installing them (or 
portions of them).

=item *

Copying all license files and additional files to the correct locations.

=back

These processes are controlled from the C<< vanilla.yml >> file (which
will be documented in a subsequent release).

=head1 PACKAGING AS AN EXECUTABLE INSTALLER

Vanilla Perl is currently bundled into an executable installer with the
Inno Setup program using the included C<< perl.iss >> script.  The 
script controls the name and location of the executable.

To create the .exe file, open C<< perl.iss >> in Inno Setup and compile it.

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
