package Perl6::Dist::Win32;

=pod

=head1 NAME

Perl6::Dist::Win32 - Build a Perl 6 distribution for Win32

=head1 DESCRIPTION

This module is a hacky first attempt to produce a standalone executable
installer for "Perl 6" on Windows.

The stack consists of GCC, dmake, various C libraries, parrot and Rakudo.

The primary user-facing result of this build process is a working
"perl6.exe" binary executable.

=cut

use 5.008;
use strict;
use base 'Perl::Dist::Strawberry';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}





#####################################################################
# Constructor

# Set up the build
sub new {
	shift->SUPER::new(
		app_id            => 'parrot',
		app_name          => 'Vanilla Parrot',
		app_publisher     => 'Vanilla Perl Project',
		app_publisher_url => 'http://vanillaperl.org/',
		image_dir         => 'C:\\parrot',

		# Build both exe and zip versions
		exe               => 0,
		zip               => 1,

		@_,
	);
}

sub install_custom {
	my $self = shift;

	# Install the parrot binary
	my $t = time;
	$self->install_parrot(
		name       => 'parrot',
		dist       => 'BSCHMAL/parrot-0.6.4.tar.gz',
		unpack_to  => 'parrot',
		license    => {
			'parrot-0.6.4/LICENSE'          => 'parrot/LICENSE',
			'parrot-0.6.4/README'           => 'parrot/README',
			'parrot-0.6.4/CREDITS'          => 'parrot/CREDITS',
			'parrot-0.6.4/README_Win32.pod' => 'parrot/README_Win32.pod',
		},
		install_to => 'parrot',
	);
	$self->trace("Completed install_parrot in " . (time - $t) . " seconds\n");

	return 1;
}

sub install_parrot {
	my $self   = shift;
	my $parrot = Perl6::Dist::Asset::Parrot->new(
		parent => $self,
		force  => $self->force,
		@_,
	);
	unless ( $self->bin_make ) {
		croak("Cannot build Parrot yet, no bin_make defined");
	}
	$self->trace("Preparing " . $parrot->name . "\n");

	# Download the file
	my $tgz = $self->_mirror(
		$parrot->url,
		$self->download_dir,
	);

	# Unpack to the build directory
	my $unpack_to = File::Spec->catdir( $self->build_dir, $parrot->unpack_to );
	if ( -d $unpack_to ) {
		$self->trace("Removing previous $unpack_to\n");
		File::Remove::remove( \1, $unpack_to );
	}
	$self->_extract( $tgz => $unpack_to );

	# Get the versioned name of the directory
	(my $parrotsrc = $tgz) =~ s{\.tar\.gz\z|\.tgz\z}{};
	$parrotsrc = File::Basename::basename($parrotsrc);

	# Build parrot
	SCOPE: {
		my $wd = File::pushd::pushd(
			File::Spec->catdir( $unpack_to, $parrotsrc ),
		);

		my $name = $parrot->name;
		$self->trace("Configuring $name...\n");
		$self->_perl( 'Makefile.PL' );

		$self->trace("Building $name...\n");
		$self->_make;

		unless ( 0 ) {
		# unless ( $perl->force ) {
			local $ENV{PERL_SKIP_TTY_TEST} = 1;
			$self->trace("Testing perl...\n");
			$self->_make('test');
		}

		
	}

	return 1;
}





#####################################################################
# Overloaded Perl::Dist Methods

sub install_perl_588 {
	my $self = shift;
	$self->SUPER::install_perl_588(@_);

	# Install the Strawberry CPAN::Config
	$self->install_file(
		share      => 'Perl6-Dist-Win32 CPAN_Config_588.pm',
		install_to => 'perl/lib/CPAN/Config.pm',
	);

	return 1;
}

sub install_perl_5100 {
	my $self = shift;
	$self->SUPER::install_perl_5100(@_);

	# Install the vanilla CPAN::Config
	$self->install_file(
		share      => 'Perl6-Dist-Win32 CPAN_Config_5100.pm',
		install_to => 'perl/lib/CPAN/Config.pm',
	);

	return 1;
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl6-Dist-Win32>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Perl::Dist>, L<http://ali.as/>

=head1 COPYRIGHT

Copyright 2008 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
