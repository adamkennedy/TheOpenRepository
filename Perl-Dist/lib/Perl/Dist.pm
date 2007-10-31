package Perl::Dist;

use 5.005;
use strict;
use Carp                  'croak';
use Archive::Tar          ();
use Archive::Zip          ();
use File::Spec            ();
use File::Spec::Unix      ();
use File::Copy            ();
use File::Copy::Recursive ();
use File::Path            ();
use File::pushd           ();
use File::Remove          ();
use File::Basename        ();
use IPC::Run3             ();
use Params::Util          qw{ _STRING _INSTANCE };
use HTTP::Status          ();
use LWP::UserAgent        ();
use LWP::Online           ();
use Tie::File             ();

use base 'Perl::Dist::Inno';

use vars qw{$VERSION};
BEGIN {
        $VERSION = '0.29_01';
}

use Object::Tiny qw{
	offline
	download_dir
	image_dir
	modules_dir
	license_dir
	build_dir
	remove_image
	user_agent
	bin_perl
	bin_make
	cpan_uri
};

use Perl::Dist::Inno;
use Perl::Dist::Asset;
use Perl::Dist::Asset::Perl;
use Perl::Dist::Asset::Binary;
use Perl::Dist::Asset::Distribution;
use Perl::Dist::Asset::Module;
use Perl::Dist::Asset::File;





#####################################################################
# Constructor

sub new {
	my $class  = shift;
	my %params = @_;

	# Apply some defaults
	if ( defined $params{image_dir} and ! defined $params{default_dir_name} ) {
		$params{default_dir_name} = $params{image_dir};
	}
	if ( defined $params{temp_dir} ) {
		unless ( defined $params{download_dir} ) {
			$params{download_dir} = File::Spec->catdir(
				$params{temp_dir}, 'download',
			);
			File::Path::mkpath($params{download_dir});
		}
		unless ( defined $params{source_dir} ) {
			$params{source_dir} = File::Spec->catdir(
				$params{temp_dir}, 'source',
			);
			if ( -d $params{source_dir} ) {
				File::Remove::remove( \1, $params{source_dir} );
			}
			File::Path::mkpath($params{source_dir});
		}
		unless ( defined $params{build_dir} ) {
			$params{build_dir} = File::Spec->catdir(
				$params{temp_dir}, 'build',
			);
			if ( -d $params{build_dir} ) {
				File::Remove::remove( \1, $params{build_dir} );
			}
			File::Path::mkpath($params{build_dir});
		}
		unless ( defined $params{output_dir} ) {
			$params{output_dir} = File::Spec->catdir(
				$params{temp_dir}, 'output',
			);
			if ( -d $params{output_dir} ) {
				File::Remove::remove( \1, $params{output_dir} );
			}
			File::Path::mkpath($params{output_dir});
		}
	}

	# Hand off to the parent class
	my $self = $class->SUPER::new(%params);

        # Apply more defaults
	unless ( defined $self->remove_image ) {
		$self->{remove_image} = 1;
	}
	unless ( defined $self->{trace} ) {
		$self->{trace} = 1;
	}

	# Auto-detect online-ness if needed
	unless ( defined $self->user_agent ) {
		$self->{user_agent} = LWP::UserAgent->new;
	}
	unless ( defined $self->offline ) {
		$self->{offline} = LWP::Online::offline();
	}

	# Normalize some params
	$self->{offline}      = !! $self->offline;
	$self->{trace}        = !! $self->{trace};
	$self->{remove_image} = !! $self->remove_image;

	# Check params
	unless ( _STRING($self->download_dir) ) {
		croak("Missing or invalid download_dir param");
	}
	unless ( defined $self->modules_dir ) {
		$self->{modules_dir} = File::Spec->catdir( $self->download_dir, 'modules' );
	}
	unless ( _STRING($self->modules_dir) ) {
		croak("Invalid modules_dir param");
	}
	unless ( _STRING($self->image_dir) ) {
		croak("Missing or invalid image_dir param");
	}
	unless ( defined $self->license_dir ) {
		$self->{license_dir} = File::Spec->catdir( $self->image_dir, 'licenses' );
	}
	unless ( _STRING($self->license_dir) ) {
		croak("Invalid license_dir param");
	}
	unless ( _STRING($self->build_dir) ) {
		croak("Missing or invalid build_dir param");
	}
	unless ( _INSTANCE($self->user_agent, 'LWP::UserAgent') ) {
		croak("Missing or invalid user_agent param");
	}
	unless ( _INSTANCE($self->cpan_uri, 'URI') ) {
		croak("Missing or invalid cpan_uri param");
	}
	unless ( $self->cpan_uri->as_string =~ /\/$/ ) {
		croak("Missing trailing slash in cpan_uri param");
	}

	# Clear the previous build
	if ( -d $self->image_dir ) {
		if ( $self->remove_image ) {
			$self->trace("Removing previous " . $self->image_dir . "\n");
			File::Remove::remove( \1, $self->image_dir );
		} else {
			croak("The image_dir directory already exists");
		}
	} else {
		$self->trace("No previous " . $self->image_dir . " found\n");
	}

	# Initialize the build
	for my $d (
		$self->download_dir,
		$self->image_dir,
		$self->modules_dir,
		$self->license_dir,
	) {
		next if -d $d;
		File::Path::mkpath($d);
	}

        return $self;
}





#####################################################################
# Main Methods

sub run {
	die "CODE INCOMPLETE";
}

sub install_binaries {
	my $self = shift;

	# Install dmake
	$self->install_binary(
		name       => 'dmake',
		share      => 'Perl-Dist-Downloads dmake-4.8-20070327-SHAY.zip',
		license    => {
			'dmake/COPYING'            => 'dmake/COPYING',
			'dmake/readme/license.txt' => 'dmake/license.txt',
		},
		install_to => {
			'dmake/dmake.exe' => 'dmake/bin/dmake.exe',	
			'dmake/startup'   => 'dmake/bin/startup',
		},
	);

	# Initialize the image_dir binaries
	$self->{bin_make} = File::Spec->catfile( $self->image_dir, 'dmake', 'bin', 'dmake.exe' );
	unless ( -x $self->bin_make ) {
		die "Can't execute make";
	}

	# Install the compilers (gcc)
	$self->install_binary(
		name       => 'gcc-core',
		share      => 'Perl-Dist-Downloads gcc-core-3.4.5-20060117-1.tar.gz',
		license    => {
			'COPYING'     => 'gcc/COPYING',
			'COPYING.lib' => 'gcc/COPYING.lib',
		},
		install_to => 'mingw',
	);
	$self->install_binary(
		name       => 'gcc-g++',
		share      => 'Perl-Dist-Downloads gcc-g++-3.4.5-20060117-1.tar.gz',
		install_to => 'mingw',
	);

	# Install the binary utilities
	$self->install_binary(
		name       => 'mingw-make',
		share      => 'Perl-Dist-Downloads mingw32-make-3.81-2.tar.gz',
		install_to => 'mingw',
	);
	$self->install_binary(
		name       => 'binutils',
		share      => 'Perl-Dist-Downloads binutils-2.17.50-20060824-1.tar.gz',
		license    => {
			'Copying'     => 'binutils/Copying',
			'Copying.lib' => 'binutils/Copying.lib',
		},
		install_to => 'mingw',
	);

	# Install support libraries
	$self->install_binary(
		name       => 'mingw-runtime',
		share      => 'Perl-Dist-Downloads mingw-runtime-3.13.tar.gz',
		license    => {
			'doc/mingw-runtime/Contributors' => 'mingw/Contributors',
			'doc/mingw-runtime/Disclaimer'   => 'mingw/Disclaimer',
		},
		install_to => 'mingw',
	);
	$self->install_binary(
		name       => 'w32api',
		share      => 'Perl-Dist-Downloads w32api-3.10.tar.gz',
		install_to => 'mingw',
		extra      => {
			'extra\README.w32api' => 'licenses\win32api\README.w32api',
		},
	);

	return 1;
}





#####################################################################
# Support Methods

sub install_binary {
	my $self   = shift;
	my $binary = Perl::Dist::Asset::Binary->new(@_);
	my $name   = $binary->name;
	$self->trace("Preparing $name\n");

	# Download the file
	my $tgz = $self->_mirror(
		$binary->url,
		File::Spec->catdir( $self->download_dir ),
	);

	# Unpack the archive
	my $install_to = $binary->install_to;
	if ( ref $binary->install_to eq 'HASH' ) {
		$self->_extract_filemap( $tgz, $binary->install_to, $self->image_dir );

	} elsif ( ! ref $binary->install_to ) {
		# unpack as a whole
		my $tgt = File::Spec->catdir( $self->image_dir, $binary->install_to );
		$self->_extract( $tgz => $tgt );

	} else {
		die "didn't expect install_to to be a " . ref $binary->install_to;
	}

	# Find the licenses
	if ( ref $binary->license eq 'HASH' )   {
		$self->_extract_filemap( $tgz, $binary->license, $self->license_dir, 1 );
	}

	# Copy in any extras (e.g. CPAN\Config.pm starter)
	my $extras = $binary->extras;
	if ( $extras ) {
		for my $from ( keys %$extras ) {
			my $to = File::Spec->catfile( $self->image_dir, $extras->{$from} );
			$self->_copy( $from => $to );
		}
	}
}

sub install_perl_588 {
	my $self = shift;
	unless ( $self->bin_make ) {
		croak("Cannot build Perl yet, no bin_make defined");
	}
	my $perl = Perl::Dist::Asset::Perl->new(@_);

	# Download the file
	my $tgz = $self->_mirror( 
		$perl->url,
		File::Spec->catdir( $self->download_dir ) 
	);

	my $unpack_to = File::Spec->catdir( $self->build_dir, $perl->unpack_to );
	if ( -d $unpack_to ) {
		$self->trace("Removing previous $unpack_to\n");
		File::Remove::remove( \1, $unpack_to );
	}
	$self->_extract( $tgz => $unpack_to );

	# Get the versioned name of the directory
	(my $perlsrc = $tgz) =~ s{\.tar\.gz\z|\.tgz\z}{};
	$perlsrc = File::Basename::basename($perlsrc);

	# Pre-copy updated files over the top of the source
	my $pre_copy = $perl->pre_copy;
	if ( $pre_copy ) {
		foreach my $f ( sort keys %$pre_copy ) {
			my $from = File::ShareDir::module_file( 'Perl::Dist', $f );
			my $to   = File::Spec->catfile(
				$unpack_to, $perlsrc, $pre_copy->{$f},
			);
			$self->_copy( $from => $to );
		}
	}

	# Copy in licenses
	my $license_dir = File::Spec->catdir( $self->image_dir, 'licenses' );
	$self->_extract_filemap( $tgz, $perl->license, $license_dir, 1 );

	# Setup fresh install directory
	my $perl_install = File::Spec->catdir( $self->image_dir, $perl->install_to );

	if ( -d $perl_install ) {
		$self->trace("Removing previous $perl_install\n");
		File::Remove::remove( \1, $perl_install );
	}

	# Build win32 perl
	SCOPE: {
		my $wd = File::pushd::pushd(
			File::Spec->catdir( $unpack_to, $perlsrc , "win32" ),
		);

		my $image_dir             = $self->image_dir;
		my (undef,$short_install) = File::Spec->splitpath( $perl_install, 1 );
		$self->trace("Patching makefile.mk\n");
		tie my @makefile, 'Tie::File', 'makefile.mk'
			or die "Couldn't read makefile.mk";
		for ( @makefile ) {
			if ( m{\AINST_TOP\s+\*=\s+} ) {
				s{\\perl}{$short_install}; # short has the leading \

			} elsif ( m{\ACCHOME\s+\*=} ) {
				s{c:\\mingw}{$image_dir\\mingw}i;

			} else {
				next;
			}
		}
		untie @makefile;

		$self->trace("Building perl...\n");
		$self->_make;

		SCOPE: {
			local $ENV{PERL_SKIP_TTY_TEST} = 1;
			$self->trace("Testing perl build\n");
			$self->_make('test');
		}

		$self->trace("Installing perl...\n");
		$self->_make( qw/install UNINST=1/ );
	}

	# Post-copy updated files over the top of the source
	my $post_copy = $perl->post_copy;
	if ( $post_copy ) {
		foreach my $f ( sort keys %$post_copy ) {
			my $from = File::ShareDir::module_file( 'Perl::Dist', $f );
			my $to   = File::Spec->catfile(
				$perl_install, $post_copy->{$f},
			);
			$self->_copy( $from => $to );
		}
	}

	# Should now have a perl to use
	$self->{bin_perl} = File::Spec->catfile( $self->image_dir, qw/perl bin perl.exe/ );
	unless ( -x $self->bin_perl ) {
		die "Can't execute " . $self->bin_perl;
	}

	return 1;
}

sub install_distribution {
	my $self = shift;
	my $dist = Perl::Dist::Asset::Distribution->new(@_);

	# Download the file
	my $tgz = $self->_mirror( 
		$dist->abs_uri( $self->cpan_uri ),
		File::Spec->catdir( $self->download_dir ) 
	);

	# Where will it get extracted to
	my $dist_path = $dist->name;
	$dist_path =~ s/\.tar\.gz//;
	$dist_path =~ s/\.zip//;
	$dist_path =~ s/.+\///;
	my $unpack_to = File::Spec->catdir( $self->build_dir, $dist_path );

	# Extract the tarball
	if ( -d $unpack_to ) {
		$self->trace("Removing previous $unpack_to\n");
		File::Remove::remove( \1, $unpack_to );
	}
	$self->_extract( $tgz => $self->build_dir );
	unless ( -d $unpack_to ) {
		croak("Failed to extract $unpack_to");
	}

	# Build the module
	SCOPE: {
		my $wd = File::pushd::pushd( $unpack_to );

		$self->trace("Configuring " . $dist->name . "...\n");
		$self->_perl( 'Makefile.PL' );

		$self->trace("Building " . $dist->name . "...\n");
		$self->_make;

		# XXX Ugh -- tests take too long right now
		$self->trace("Testing " . $dist->name . "\n");
		$self->_make('test');

		$self->trace("Installing " . $dist->name . "...\n");
		$self->_make( qw/install UNINST=1/ );
	}

	return 1;
}

sub trace {
	my $self = shift;
	if ( $self->{trace} ) {
		print $_[0];
	}
	return 1;
}

sub _mirror {
	my ($self, $url, $dir) = @_;
	my ($file) = $url =~ m{/([^/?]+\.(?:tar\.gz|tgz|zip))}ims;
	my $target = File::Spec->catfile( $dir, $file );
	if ( $self->offline and -f $target ) {
		$self->trace(" already downloaded\n");
		return $target;
	}
	if ( $self->offline and ! $url =~ m|^file://| ) {
		$self->trace(" offline, cannot download.");
		exit(0);
	}
	File::Path::mkpath($dir);
	$| = 1;

	$self->trace("Downloading $file...");
	my $ua = LWP::UserAgent->new;
	my $r  = $ua->mirror( $url, $target );
	if ( $r->is_error ) {
		$self->trace("    Error getting $url:\n" . $r->as_string . "\n");

	} elsif ( $r->code == HTTP::Status::RC_NOT_MODIFIED ) {
		$self->trace(" already up to date.\n");

	} else {
		$self->trace(" done\n");
	}

	return $target;
}

sub _copy {
	my ($self, $from, $to) = @_;
	my $basedir = File::Basename::dirname( $to );
	File::Path::mkpath($basedir) unless -e $basedir;
	$self->trace("Copying $from to $to\n");
	File::Copy::Recursive::rcopy( $from, $to ) or die $!;
}

sub _make {
	my $self   = shift;
	my @params = @_;
	$self->trace(join(' ', '>', $self->bin_make, @params) . "\n");
	IPC::Run3::run3( [ $self->bin_make, @params ], \undef, \undef, \undef ) or die "make failed";
	die "make failed (OS error)" if ( $? >> 8 );
	return 1;
}

sub _perl {
	my $self   = shift;
	my @params = @_;
	$self->trace(join(' ', '>', $self->bin_perl, @params) . "\n");
	IPC::Run3::run3( [ $self->bin_perl, @params ], \undef, \undef, \undef ) or die "perl failed";
	die "perl failed (OS error)" if ( $? >> 8 );
	return 1;
}

sub _extract {
	my ( $self, $from, $to ) = @_;
	File::Path::mkpath($to);
	my $wd = File::pushd::pushd( $to );
	$|++;
	$self->trace("Extracting $from...");
	if ( $from =~ m{\.zip\z} ) {
		my $zip = Archive::Zip->new( $from );
		$zip->extractTree();
		$self->trace("done\n");

	} elsif ( $from =~ m{\.tar\.gz|\.tgz} ) {
		local $Archive::Tar::CHMOD = 0;
		Archive::Tar->extract_archive($from, 1);
		$self->trace("done\n");

	} else {
		die "Didn't recognize archive type for $from";
	}
	return 1;
}


sub _extract_filemap {
	my ( $self, $archive, $filemap, $basedir, $file_only ) = @_;

	if ( $archive =~ m{\.zip\z} ) {
		my $zip = Archive::Zip->new( $archive );
		my $wd = File::pushd::pushd( $basedir );
		while ( my ($f, $t) = each %$filemap ) {
			$self->trace("Extracting $f to $t\n");
			my $dest = File::Spec->catfile( $basedir, $t );
			$zip->extractTree( $f, $dest );
		}

	} elsif ( $archive =~ m{\.tar\.gz|\.tgz} ) {
		local $Archive::Tar::CHMOD = 0;
		my $tar = Archive::Tar->new( $archive );
		for my $file ( $tar->get_files ) {
			my $f = $file->full_path;
			my $canon_f = File::Spec::Unix->canonpath( $f );
			for my $tgt ( keys %$filemap ) {
				my $canon_tgt = File::Spec::Unix->canonpath( $tgt );
				my $t;

				# say "matching $canon_f vs $canon_tgt";
				if ( $file_only ) {
					next unless $canon_f =~ m{\A([^/]+[/])?\Q$canon_tgt\E\z}i;
					($t = $canon_f)   =~ s{\A([^/]+[/])?\Q$canon_tgt\E\z}
	             				{$filemap->{$tgt}}i;

				} else {
					next unless $canon_f =~ m{\A([^/]+[/])?\Q$canon_tgt\E}i;
					($t = $canon_f) =~ s{\A([^/]+[/])?\Q$canon_tgt\E}
	             				{$filemap->{$tgt}}i;
				}
				my $full_t = File::Spec->catfile( $basedir, $t );
				$self->trace("Extracting $f to $full_t\n");
				$tar->extract_file( $f, $full_t );
			}
		}

	} else {
		die "Didn't recognize archive type for $archive";
	}

	return 1;
}

1;

__END__

=pod

=head1 NAME

Perl::Dist - Perl Distribution Creation Toolkit

=head1 DESCRIPTION

The Perl::Dist namespace encompasses creation of pre-packaged, binary
distributions of Perl, such as executable installers for Win32.  While initial
efforts are targeted at Win32, there is hope that this may become a more
general support tool for Perl application deployment.

Packages in this namespace include both "builders" and "distributions".
Builder packages automate the generation of distributions.  Distribution
packages contain configuration files for a particular builder, extra files
to be bundled with the pre-packaged binary, and documentation.
Distribution namespaces are also recommended to consolidate bug reporting
using http://rt.cpan.org/.

I<Distribution packages should not contain the pre-packaged install files
themselves.>

B<Please note that this module is currently considered experimental, and
not really suitable for general use>.

=head2 BUILDERS

There is currently only the default builder:

=over

=item *

L<Perl::Dist::Builder> -- an alpha version of a distribution builder

=back

=head2 DISTRIBUTIONS

Currently available distributions include:

=over

=item *

L<Perl::Dist::Vanilla> -- an experimental "core Perl" distribution intended
for distribution developers

=item *

L<Perl::Dist::Strawberry> -- a practical Win32 Perl release for
experienced Perl developers to experiment and test the installation of
various CPAN modules under Win32 conditions

=back

=head1 ROADMAP

Everything is currently alpha, at best.  These packages have been released
to enable community support in ongoing development.

Some specific items for development include:

=over

=item *

Bug-squashing Win32 compatibility problems in popular modules

=item *

Refactoring the initial builder for greater modularity and control of the
build process

=item *

Support for Win32 *.msi installation files instead of standalone *.exe
installers

=item *

Better uninstall support and upgradability

=back

=head1 AUTHOR

Adam Kennedy <adamk@cpan.org>

David A. Golden <dagolden@cpan.org>

=head1 COPYRIGHT

Cyopright 2007 Adam Kennedy

Copyright 2006 David A. Golden

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

=over

=item *

L<Perl::Dist::Builder>

=item *

L<Perl::Dist::Vanilla>

=item *

L<Perl::Dist::Strawberry>

=item *

L<http://win32.perl.org/>

=item *

L<http://vanillaperl.com/>

=item *

L<irc://irc.perl.org/#win32>

=item *

L<http://ali.as/>

=item *

L<http://dagolden.com/>

=back

=cut
