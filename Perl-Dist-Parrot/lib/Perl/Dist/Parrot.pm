package Perl::Dist::Parrot;

=pod

=head1 NAME

Perl::Dist::Parrot - Parrot and its languages for Win32

=head1 DESCRIPTION

This is an experimental distribution builder, aiming to create a usable
installer for Parrot (and Rakudo, the Perl 6 implementation) on Windows.

=cut

use 5.008;
use strict;
use warnings;
use Perl::Dist::Vanilla       ();
use Perl::Dist::Asset::Parrot ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION  = '0.01';
	@ISA      = 'Perl::Dist::Vanilla';
}

use Object::Tiny qw{
	bin_mingw_make
};





#####################################################################
# Configuration

sub new {
	shift->SUPER::new(
		app_id               => 'perl6',
		app_name             => 'Vanilla Perl 6',
		app_publisher        => 'Vanilla Perl Project',
		app_publisher_url    => 'http://vanillaperl.org/',
		app_ver_name         => 'Vanilla Perl 6 0.8.1 Alpha 1',
		output_base_filename => 'vanilla-perl6-0.8.1-alpha-1',
		image_dir            => 'C:\\perl6',
		build_dir            => 'C:\\build',
		perl_version         => 588,

		# Build both exe and zip versions
		exe                  => 1,
		zip                  => 1,

		@_,
	);
}

sub perl6_dir {
	File::Spec->catdir(
		$_[0]->image_dir,
		'perl6',
	);
}





#####################################################################
# C Toolchain

sub install_mingw_make {
	my $self = shift;
	$self->SUPER::install_mingw_make(@_);

	# Initialize the MinGW make location
	$self->{bin_mingw_make} = File::Spec->catfile(
		$self->image_dir, 'c', 'bin', 'mingw32-make.exe',
	);
	unless ( -x $self->bin_mingw_make ) {
		Carp::croak("Can't execute mingw_make");
	}

	return 1;
}





#####################################################################
# Win32 Entities

# Remove the strawberry menu stuff
sub install_win32_extras {
	return 1;
}





#####################################################################
# Custom Installation

sub install_custom {
	my $self = shift;

	# Install Parrot
	$self->install_parrot_081;

	return 1;
}

sub install_parrot_081 {
	my $self = shift;

	$self->install_parrot_081_bin(
		name       => 'parrot',
		url        => 'http://strawberryperl.com/package/parrot-0.8.1.tar.gz',
		unpack_to  => 'parrot',
		install_to => 'perl6',
		license    => {
			'parrot-0.8.1/LICENSE' => 'parrot/LICENSE',
		},
	);

	return 1;
}

sub install_parrot_081_bin {
	my $self   = shift;
	my $parrot = Perl::Dist::Asset::Parrot->new(
		parent => $self,
		force  => $self->force,
		@_,
	);
	unless ( $self->bin_make ) {
		Carp::croak("Cannot build Perl yet, no bin_make defined");
	}

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

	# Pre-copy updated files over the top of the source
	my $patch = $parrot->patch;
	if ( $patch ) {
		# Overwrite the appropriate files
		foreach my $file ( @$patch ) {
			$self->patch_file( "perl-5.8.8/$file" => $unpack_to );
		}
	}

	# Copy in licenses
	if ( ref $parrot->license eq 'HASH' ) {
		my $license_dir = File::Spec->catdir( $self->image_dir, 'licenses' );
		$self->_extract_filemap( $tgz, $parrot->license, $license_dir, 1 );
	}

	# Build win32 Parrot
	SCOPE: {
		my $wd = File::pushd::pushd(
			File::Spec->catdir( $unpack_to, $parrotsrc ),
		);

		# Configure Parrot
		my $dir = $self->perl6_dir;
		$self->trace("Configuring Parrot...\n");
		$self->_perl("Configure.pl", "--prefix=$dir");

		# Make Parrot
		$self->trace("Making Parrot...\n");
		$self->_mingw_make('world');

		# Make Perl 6
		$self->trace("Making Perl 6...\n");
		$self->_mingw_make('perl6');

		# Test it all
		unless ( 1 ) {
			$self->trace("Testing perl...\n");
			$self->_mingw_make('test');
		}

		# Install Parrot and Perl 6
		$self->trace("Installing Parrot/Perl 6");
		$self->_mingw_make('reallyinstall');

		# Flush and reset the PATH environment
		$self->clear_env_path;
		$self->add_env_path( 'perl6', 'bin' );
	}

	return 1;
}





#####################################################################
# Support Methods

sub clear_env_path {
	my $self = shift;
	$self->{env_path} = [];
	return 1;
}

sub _mingw_make {
	my $self   = shift;
	my @params = @_;
	$self->trace(join(' ', '>', $self->bin_mingw_make, @params) . "\n");
	$self->_run3( $self->bin_mingw_make, @params ) or die "mingw_make failed";
	die "mingw_make failed (OS error)" if ( $? >> 8 );
	return 1;
}

1;

=pod

=head1 SUPPORT

There is no support.

=head1 COPYRIGHT

Copyright 2008 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
