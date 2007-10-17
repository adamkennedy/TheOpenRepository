package Perl::Dist::Vanilla::Build;
$VERSION = 7;
use strict;

1;
__END__

=head1 NAME

Perl::Dist::Vanilla::Build - Building Vanilla Perl from scratch

=head1 DESCRIPTION

The Perl::Dist::Vanilla distribution on CPAN contains scripts and instructions
for downloading component sources and assembling them into the executable
installer for Vanilla Perl.  It B<does not> include the resulting Vanilla Perl
installation itself.  

This document describes the build process for generating a Vanilla Perl
executable installer.  

=head1 PREREQUISITES

Perl::Dist::Vanilla requires an existing Win32 Perl installation to bootstrap
the installation process and L<Perl::Dist::Builder>.  See
L<Perl::Dist::Bootstrap> for details on bootstrapping a Perl that can build
Vanilla Perl.

Perl::Dist::Vanilla also requires the free Inno Setup tool to create the 
executable installer.  Inno Setup can be downloaded from jrsoftware.org:

L<http://www.jrsoftware.org/isinfo.php>

=head1 BUILDING THE INSTALLATION SOURCE DIRECTORY

From the Perl::Dist::Vanilla tarball directory, the C<< bin\build_all.pl >>
program will build a full Vanilla Perl installation.  This includes:

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
Inno Setup program using the included C<< vanilla.iss >> script.  The 
script controls the name and location of the executable.

To create the .exe file, open C<< vanilla.iss >> in Inno Setup and compile it.

If the Inno Setup tool is in a standard location, the C<bin\run_inno_setup.pl>
script will compile vanilla.iss from the command line.

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
