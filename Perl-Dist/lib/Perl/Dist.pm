package Perl::Dist;

use 5.005;
use strict;
use Carp 'croak';
use base 'Perl::Dist::Inno';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.10';
}

use Object::Tiny qw{
	offline
	download_dir
	image_dir
	remove_image
	user_agent
	asset_perl
	bin_perl
	bin_make
};





#####################################################################
# Constructor

sub new {
	my $class  = shift;
	my %params = @_;

	# Apply some defaults
	unless ( defined $params{default_dir_name} ) {
		if ( $params{image_dir} ) {
			$params{default_dir_name} = $params{image_dir};
		} else {
			croak("Missing or invalid image_dir param");
		}
	}
	unless ( defined $params{user_agent} ) {
		$params{user_agent} = LWP::UserAgent->new;
	}

	# Hand off to the parent class
	my $self = shift->SUPER::new(%params);

	# Auto-detect online-ness if needed
	unless ( defined $self->{offline} ) {
		$self->{offline} = LWP::Online::offline();
	}

	# Normalize some params
	$self->{offline}      = !! $self->offline;
	$self->{remove_image} = !! $self->remove_image;

	# Check params
	unless ( _STRING($self->download_dir) ) {
		croak("Missing or invalid download_dir param");
	}
	unless ( _STRING($self->image_dir) ) {
		croak("Missing or invalid image_dir param");
	}
	unless ( _INSTANCE($self->user_agent, 'LWP::UserAgent') ) {
		croak("Missing or invalid user_agent param");
	}

	# Clear the previous build
	if ( -d $self->image_dir ) {
		if ( $self->remove_image ) {
			$self->trace("Removing previous $image\n");
			File::Remove::remove( \1, $image );
		} else {
			croak("The image_dir directory already exists");
		}
	} else {
		$self->trace("No previous $image found\n");
	}

	# Initialize the build
	File::Path::mkpath($self->image_dir);
	for my $d ( qw/dmake mingw licenses links perl/ ) {
		File::Path::mkpath(
			File::Spec->catdir( $dir, $d )
		);
	}

	# Create the working directories
	for my $d ( $self->download_dir, $self->image_dir ) {
		next if -d $d;
		File::Path::mkpath($d) or die "Couldn't create $d";
	}

        return $self;
}





#####################################################################
# Main Methods

sub run {

}

sub install_binary {
	my $self = shift;

	
}

sub install_perl_588 {
	my $self = shift;
	unless ( $self->bin_make ) {
		croak("Cannot build Perl yet, no bin_make defined");
	}
	if ( $self->asset_perl ) {
		croak("A version of Perl has already been built");
	}
	my $perl = $self->{asset_perl} = Perl::Dist::Asset::Perl->new(@_);

	# Download the file
	my $tgz = $self->_mirror( 
		$perl->url,
		File::Spec->catdir( $self->download_dir, $perl->name ) 
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

	# Manually patch in the Win32 friendly ExtUtils::Install
	for my $f ( qw/Install.pm Installed.pm Packlist.pm/ ) {
		my $from = File::Spec->catfile( "extra", $f );
		my $to   = File::Spec->catfile( $unpack_to, $perlsrc, qw/lib ExtUtils/, $f );
		$self->_copy( $from => $to );
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

		# XXX Ugh -- tests take too long right now
		$self->trace("Testing perl build\n");
		$self->_make('test');

		$self->trace("Installing perl...\n");
		$self->_make( qw/install UNINST=1/ );
	}

	# Copy in any extras (e.g. CPAN\Config.pm starter)
	if ( my $extras = $perl->{after} ) {
		for my $f ( keys %$extras ) {
			my $from = File::Spec->catfile( $f );
			my $to   = File::Spec->catfile( $perl_install, $extras->{$f} );
			$self->_copy( $from => $to );
		}
	}

	# Should now have a perl to use
	$self->{bin_perl} = File::Spec->catfile( $self->image_dir, qw/perl bin perl.exe/ );
	unless ( -x $self->bin_perl ) {
		die "Can't execute " . $self->bin_perl;
	}

	return $self;
}





#####################################################################
# Support Methods

sub trace {
	print $_[0];
}

sub _mirror {
	my ($self, $url, $dir) = @_;
	my ($file) = $url =~ m{/([^/?]+\.(?:tar\.gz|tgz|zip))}ims;
	my $target = File::Spec->catfile( $dir, $file );
	if ( $self->{offline} and -f $target ) {
		$self->trace(" already downloaded\n");
		return $target;
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
	IPC::Run3::run3( [ $self->bin_make, @params ] ) or die "make failed";
	die "make failed (OS error)" if ( $? >> 8 );
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
