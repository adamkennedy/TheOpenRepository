package Perl::Dist::Glutamate;

use 5.005;
use strict;
use base 'Perl::Dist::Strawberry';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}





#####################################################################
# Configuration

# Apply some default paths
sub new {
	shift->SUPER::new(
		app_id            => 'glutamateperl',
		app_name          => 'Glutamate Perl',
		app_publisher     => 'Vanilla Perl Project',
		app_publisher_url => 'http://vanillaperl.org/',
		image_dir         => 'C:\\glutamate-perl',
		@_,
	);
}

# Lazily default the full name.
# Supports building multiple versions of Perl.
sub app_ver_name {
	$_[0]->{app_ver_name} or
	$_[0]->app_name . ' ' . $_[0]->perl_version_human . ' Update 1';
}

# Lazily default the file name
# Supports building multiple versions of Perl.
sub output_base_filename {
	$_[0]->{output_base_filename} or
	'glutamate-perl-' . $_[0]->perl_version_human . '-update-1';
}





#####################################################################
# Customisations for C assets

sub install_c_libraries {
	my $self = shift;
	# FIXME turn back on when Strawberry works for expat
	#$self->SUPER::install_c_libraries(@_);

	# Install various XML-related modules
	# FIXME: Done by Strawberry usually
	$self->install_zlib;
	$self->install_libiconv;
	$self->install_libxml;

	# Install libgmp (something to do with math)
#	$self->install_gmp;
#	$self->install_expat;

	return 1;
}





#####################################################################
# Customisations for Perl assets

sub install_perl_588 {
	my $self = shift;
	$self->SUPER::install_perl_588(@_);

	# Install the custom CPAN::Config
	$self->install_file(
		share      => 'Perl-Dist-Glutamate CPAN_Config_588.pm',
		install_to => 'perl/lib/CPAN/Config.pm',
	);

	return 1;
}

sub install_perl_5100 {
	my $self = shift;
	$self->SUPER::install_perl_5100(@_);

	# Install the custom CPAN::Config
	$self->install_file(
		share      => 'Perl-Dist-Glutamate CPAN_Config_5100.pm',
		install_to => 'perl/lib/CPAN/Config.pm',
	);

	return 1;
}

sub install_perl_modules {
	my $self = shift;

	# done by strawberry:
	# Install the companion Perl modules for the
	# various libs we installed.
#		name => 'XML::LibXML',
#		name => 'Params::Util',
#		name => 'Bundle::LWP',
#		name => 'Bundle::CPAN',
#		name => 'pler',
#		name => 'pip',
#		name => 'PAR::Dist',
#		name => 'DBI',
#		name  => 'MSERGEANT/DBD-SQLite-1.14.tar.gz', force => 1,
#		name => 'CPAN::SQLite',
#		name => 'Bundle::libwin32',

	$self->install_par(
		name => 'Perl-Dist-PrepackagedPAR-libexpat',
		url  => 'http://parrepository.de/Perl-Dist-PrepackagedPAR-libexpat-2.0.1-MSWin32-x86-multi-thread-anyversion.par',
	);

	$self->install_module(
		name => 'XML::Parser',
	);
	# fails!?
#	$self->install_module(
#		name => 'PAR::Packer',
#	);
	#$self->install_module(
#		name => 'SREZIC/Tk-804.028.tar.gz',
#		force => 1,
#	);

	$self->install_module(
		name => 'PAR::Dist::InstallPPD',
	);

#	FIXME: Tk causing trouble
#	$self->install_module(
#		name => 'PAR::Dist::InstallPPD::GUI',
#	);

#	FIXME: DBM::Deep causing trouble
#	$self->install_module(
#		name => 'PAR::Repository::Client',
#	);
	$self->install_module(
		name => 'Alien::wxWidgets',
	);
	$self->install_module(
		name => 'Wx',
	);

	return 1;
}

1;

__END__

=head1 NAME

Perl::Dist::Glutamate - Glutamate Developer Perl for win32

=head1 DESCRIPTION

I<Glutamate Perl is currently an alpha release and is not recommended 
for production purposes.>

Glutamate Perl is a binary distribution of Perl for the Windows operating
system.  It is based on the Strawberry Perl distribution aimed at Win32
Perl developers and in addition to the Strawberry Perl components, it
bundles various developer tools.

Glutamate Perl includes:

=over

=item *

All components of the Strawberry Perl distribution

=item *

PAR::Packer and the C<pp> command line packager for packaging Perl applications

=item *

The Tk GUI toolkit.

=item *

Alien::wxWidgets and Wx.pm.

=item *

PAR::Dist::FromPPD, PAR::Dist::InstallPPD, PAR::Dist::InstallPPD::GUI,
and PAR::Repository::Client
in order to be able to install PPD/PPM binary distributions with ease.
(DBM::Deep is a dependency of the repository client.)

=item *

PAR::Dist::FromCPAN for generating .par's from CPAN distributions.

=item *

PAR::WebStart

=back

The Perl::Dist::Glutamate distribution on CPAN contains programs and
instructions for downloading component sources and assembling them into the
executable installer for Glutamate Perl.  It B<does not> include the resulting
Glutamate Perl installer itself.  

See L</"DOWNLOADING THE INSTALLER"> for instructions on where to download and
how to install Glutamate Perl.  

See L<Perl::Dist> at L<http://search.cpan.org> for details on 
the builder used to create Glutamate Perl from source.

=head1 DOWNLOADING THE INSTALLER

Glutamate Perl is available from ... somewhere.

=head1 CONFIGURATION

At present, Glutamate Perl must be installed in C:\glutamate-perl.  The
executable installer adds the following environment variable changes:

    * adds directories to PATH
        - C:\glutamate-perl\perl\bin  
        - C:\glutamate-perl\dmake\bin
        - C:\glutamate-perl\mingw
        - C:\glutamate-perl\mingw\bin

    * adds directories to LIB
        - C:\glutamate-perl\mingw\lib
        - C:\glutamate-perl\perl\bin

    * adds directories to INCLUDE 
        - C:\glutamate-perl\mingw\include 
        - C:\glutamate-perl\perl\lib\CORE 
        - C:\glutamate-perl\perl\lib\encode

LIB and INCLUDE changes are likely more than are necessary, but attempt to
head off potential problems compiling external programs for use with Perl.

Users installing Glutamate Perl without the installer will need to
change their environment variables manually.

The first time that the "cpan" program is run, users will be prompted for
configuration settings.  With the defaults provided in Glutamate Perl, users
may answer "no" to manual configuration and the installation should still work.

Manual CPAN configuration may be repeated by running the following command:

    perl -MCPAN::FirstTime -e "CPAN::FirstTime::init"

=head1 CONTACTS AND BUGS REPORTING

Currently, Glutamate Perl discussion is centered at win32.perl.org.  New 
venues for discussion may be listed there.

Please report bugs or feature requests using the CPAN Request Tracker.
Bugs can be sent by email to C<<< bug-Perl-Dist-Glutamate@rt.cpan.org >>> or
submitted using the web interface at
L<http://rt.cpan.org/Dist/Display.html?Queue=Perl-Dist-Glutamate>

=head1 LICENSE AND COPYRIGHT

Glutamate Perl is open source and may be licensed under the same terms as
Perl.  Open source software included with Glutamate Perl installations are
governed by their respective licenses.  See LICENSE.txt for details.

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
