package Perl::Dist::Builder;

use 5.005;
use strict;

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.30';
}

use Carp                  ();
use File::Spec            ();
use File::Spec::Unix      ();
use File::Basename        ();
use File::Path            ();
use File::Remove          ();
use File::Copy::Recursive ();
use File::Find::Rule      ();
use File::pushd           ();
use File::ShareDir        ();
use Tie::File             ();
use IPC::Run3             ();
use Archive::Tar          ();
use Archive::Zip          ();
use LWP::UserAgent        ();
use LWP::Online           ();
use HTTP::Status          ();
use URI::file             ();
use YAML::Tiny            ();
use CPAN                  ();
use Perl::Dist::Downloads ();





#####################################################################
# Constructor and Accessors

sub new {
	my $class  = shift;
	my ($self) = YAML::Tiny::LoadFile( shift );
	bless $self, $class;

	# Auto-detect online-ness if needed
	unless ( defined $self->{offline} ) {
		$self->{offline} = LWP::Online::offline();
	}

	return $self;
}

sub binary {
	$_[0]->{binary};
}

sub download_dir {
	$_[0]->{download_dir};
}

sub image_dir {
	$_[0]->{image_dir};
}

sub build_dir {
	$_[0]->{build_dir};
}

sub binaries {
	@{ $_[0]->{binary} };
}

sub modules {
	@{ $_[0]->{modules} };
}

sub bin_perl {
	$_[0]->{bin_perl} or die "perl is not ready";
}

sub bin_make {
	$_[0]->{bin_make} or die "make is not ready";
}





#####################################################################
# Main Methods

sub build_all {
	my $self = shift;
	$self->install_binaries;
	$self->install_perl;
	$self->install_modules;
	$self->install_extras;
	$self->install_from_cpan;
	return 1;
}

sub install_binaries {
	my $self = shift;

	# Clear any existing directory
	my $image_dir = $self->image_dir;
	if ( -d $image_dir ) {
		$self->trace("Removing existing image_dir $image_dir\n");
		File::Remove::remove( \1, $self->image_dir );
	}

	$self->trace("Creating $image_dir\n");
	$self->_init_dir( $image_dir );

	for my $d ( $self->download_dir, $image_dir ) {
		next if -d $d;
		File::Path::mkpath($d) or die "Couldn't create $d";
	}

	for my $binary ( $self->binaries ) {
		my $name = $binary->{name};
		$self->trace("Preparing $name\n");

		# If a share, map to a URI
		if ( $binary->{share} ) {
			my ($dist, $name) = split /\s+/, $binary->{share};
			$self->trace("Finding $name in $dist... ");
			my $file = File::Spec->rel2abs(
				File::ShareDir::dist_file( $dist, $name )
			);
			unless ( -f $file ) {
				die "Failed to find $file";
			}
			$binary->{url} = URI::file->new($file)->as_string;
			$self->trace(" found\n");
		}

		# Download the file
		my $tgz = $self->_mirror(
			$binary->{url},
			File::Spec->catdir( $self->download_dir, $name ),
		);

		# Unpack the archive
		my $install_to = $binary->{install_to} || q{};
		if ( ref $install_to eq 'HASH' ) {
			$self->_extract_filemap( $tgz, $install_to, $image_dir );

		} elsif ( ! ref $install_to ) {
			# unpack as a whole
			my $tgt = File::Spec->catdir( $image_dir, $install_to );
			$self->_extract_whole( $tgz => $tgt );

		} else {
			die "didn't expect install_to to be a " . ref $install_to;
		}

		# Find the licenses
		if ( ref $binary->{license} eq 'HASH' )   {
			my $license_dir = File::Spec->catdir( $image_dir, 'licenses' );
			$self->_extract_filemap( $tgz, $binary->{license}, $license_dir, 1 );
		}

		# Copy in any extras (e.g. CPAN\Config.pm starter)
		if ( my $extras = $binary->{extra} ) {
			for my $from ( keys %$extras ) {
				my $to   = File::Spec->catfile( $image_dir, $extras->{$from} );
				$self->_copy( $from => $to );
			}
		}
	}

	# Initialize the image_dir binaries
	$self->{bin_make} = File::Spec->catfile( $self->image_dir, 'dmake', 'bin', 'dmake.exe' );
	unless ( -x $self->bin_make ) {
		die "Can't execute make";
	}

	return 1;
}

sub install_extras {
	# Load configurations
	my $self   = shift;
	my $extras = $self->{extra}; # Hash

	# recursively copy in any extras (e.g. CPAN\Config.pm starter)
	if ( ref $extras eq 'HASH' ) {
		for my $f ( keys %$extras ) {
			my $from = $f;
			my $to   = File::Spec->catfile( $self->image_dir, $extras->{$f} );
			$self->_copy($from => $to);
		}
	}

        return 1;
}

sub install_modules {
	my $self = shift;

	# Setup a directory
	my $module_dir = File::Spec->catdir( $self->download_dir, 'modules' );

	# Get various cpan modules to include
	my @build_queue;
	my %saw_dist;
	my $url_prefix = "http://mirrors.kernel.org/CPAN/authors/id/";
	for my $mod ( $self->modules ) {
		my $mod_type = $mod->{type} || 'Module';
		# figure out the dist for the module
		my $mod_info = CPAN::Shell->expandany( $mod->{name})
			or die "Couldn't expand ", $mod->{name};
		my $cpan_file = 
			ref $mod_info eq 'CPAN::Module'       ? $mod_info->cpan_file :
			ref $mod_info eq 'CPAN::Distribution' ? $mod_info->id :
			$mod->{name};

		next if $saw_dist{ $cpan_file }++;

		# download
		my $tgz = $self->_mirror( $url_prefix . $cpan_file, $module_dir );

		my $dist_name = File::Basename::basename( $cpan_file );
		(my $extract_dir = $dist_name) =~ s{\.tar\.gz\z|\.tgz\z|\.zip\z}{};
		my ($unpack_dir, $target);

		if ( exists $mod->{unpack_to} and ref $mod->{unpack_to} eq 'HASH') {
			# individual subdirs
			$self->trace("Extracting individual files from $dist_name\n");
			$unpack_dir = $target = $self->build_dir;
			$self->_extract_filemap( $tgz, $mod->{unpack_to}, $unpack_dir );
			push @build_queue, map { [$_, $mod ] } values %{ $mod->{unpack_to} }; 

		} else {
			# normal
			# queue the resulting destination
			$unpack_dir = defined $mod->{unpack_to}
				? File::Spec->catdir( $self->build_dir, $mod->{unpack_to} )
				: $self->build_dir
			;
			my $queue_dir = defined $mod->{unpack_to}
				? File::Spec->catdir( $mod->{unpack_to}, $extract_dir )
				: $extract_dir
			; 
			$target = File::Spec->catdir( $unpack_dir, $extract_dir );
			push @build_queue, [$queue_dir, $mod];
			# unpack the tarball
			if ( -d $target ) {
				$self->trace("Removing previous $target\n");
				File::Remove::remove( \1, $target );
			}

			$self->_extract_whole( $tgz, $unpack_dir );
		}

		# copy in any extras (like config files)
		if ( my $extras = $mod->{extra} ) {
			for my $f ( keys %$extras ) {
				my $from = File::Spec->catfile( $f );
				my $to   = File::Spec->catfile( $target, $extras->{$f} );
				$self->_copy( $from => $to );
			}
		}
	}

	# Build each distribution in order
	for my $dist ( @build_queue ) {
		my ($dir, $mod) = @$dist;
		my $wd = File::pushd::pushd(
			File::Spec->catdir( $self->build_dir, $dir ),
		);

		# warn "Needs better INSTALLDIRS handling!";
		$self->trace("Building $dir\n");
		SCOPE: {
			local $ENV{PERL_MM_USE_DEFAULT} = 1;
			IPC::Run3::run3 [ $self->bin_perl, qw/
				Makefile.PL
				INSTALLDIRS=site
				INSTALLMAN1DIR=none
				INSTALLMAN3DIR=none
				INSTALLSITEMAN1DIR=none
				INSTALLSITEMAN3DIR=none
				INSTALLVENDORMAN1DIR=none
				INSTALLVENDORMAN3DIR=none
			/ ];
			-r File::Spec->catfile( $wd, 'Makefile' ) 
				or die "Problem running $dir Makefile.PL";
			$self->_make;
			IPC::Run3::run3 [ $self->bin_make, qw/test/ ];
			if ( $? >> 8 and ! $mod->{force} ) {
				$self->trace("Problem testing $dir.  Continue (y/N)?\n");
				my $answer = <>;
				exit 1 if $answer !~ /\Ay/i;
			}
			$self->_make( qw/install UNINST=1/ );
		}
	}

        return 1;
}

sub install_perl {
	# Load configurations
	my $self    = shift;
	my $sources = $self->{source}; # AOH

	# Setup directory
	$self->_init_dir( $self->image_dir );

	# download perl
	$self->trace("Building perl:\n");

	# perl is the only one so far
	my $perl_cfg = $sources->[0];

	# If a share, map to a URI
	if ( $perl_cfg->{share} ) {
		my ($dist, $name) = split /\s+/, $perl_cfg->{share};
		$self->trace("Finding $name in $dist... ");
		my $file = File::Spec->rel2abs(
			File::ShareDir::dist_file( $dist, $name )
		);
		unless ( -f $file ) {
			die "Failed to find $file";
		}
		$perl_cfg->{url} = URI::file->new($file)->as_string;
		$self->trace(" found\n");
	}

	# Download the file
	my $tgz = $self->_mirror( 
		$perl_cfg->{url},
		File::Spec->catdir( $self->download_dir, $perl_cfg->{name} ) 
	);

	my $unpack_to = File::Spec->catdir( $self->build_dir, ( $perl_cfg->{unpack_to} || q{} ) );
	if ( -d $unpack_to ) {
		$self->trace("Removing previous $unpack_to\n");
		File::Remove::remove( \1, $unpack_to );
	}

	$self->_extract_whole( $tgz => $unpack_to );

	# Get the versioned name of the directory
	(my $perlsrc = $tgz) =~ s{\.tar\.gz\z|\.tgz\z}{};
	$perlsrc = File::Basename::basename($perlsrc);

	# Manually patch in the Win32 friendly ExtUtils::Install
	for my $f ( qw/Install.pm Installed.pm Packlist.pm/ ) {
		my $from = File::Spec->catfile( "extra", $f );
		my $to   = File::Spec->catfile( $unpack_to, $perlsrc, qw/lib ExtUtils/, $f );
		$self->_copy( $from => $to );
	}

	# finding licenses
	if ( ref $perl_cfg->{license} eq 'HASH' )   {
		my $license_dir = File::Spec->catdir( $self->image_dir, 'licenses' );
		$self->_extract_filemap( $tgz, $perl_cfg->{license}, $license_dir, 1 );
	}

	# Setup fresh install directory
	my $perl_install = File::Spec->catdir( $self->image_dir, $perl_cfg->{install_to} );

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
		# $self->trace("Testing perl build\n");
		# $self->_make('test');

		$self->trace("Installing perl...\n");
		$self->_make( qw/install UNINST=1/ );
	}

	# Copy in any extras (e.g. CPAN\Config.pm starter)
	if ( my $extras = $perl_cfg->{after} ) {
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

	$self->trace("Perl build completed ok\n");
        return 1;
}

sub install_from_cpan {
	# Load configurations
	my $self = shift;
	my $cpan = $self->{cpan} or return; # AOH

	# Get various cpan modules to include
	for my $mod ( @$cpan ) {
		my $name     = $mod->{name};
		my $force    = $mod->{force} ? 1 : 0;
		my $cpan_str = <<"END_PERL";
print( "-" x 70, "\n" );
print "Preparing to install $name from CPAN\n";
\$obj = CPAN::Shell->expandany( "$name" ) 
	or die "CPAN.pm couldn't locate $name";
if ( \$obj->uptodate ) {
	print "$name is up to date\n";
	exit
}
if ( $force ) {
	local \$ENV{PERL_MM_USE_DEFAULT} = 1;
	\$obj->force("install");
	\$CPAN::DEBUG=1;
	\$obj->uptodate or 
		die "Forced installation of $name appears to have failed";
}
else {
	local \$ENV{PERL_MM_USE_DEFAULT} = 1;
	\$obj->install;
	\$obj->uptodate or 
		die "Installation of $name appears to have failed";
}
END_PERL
		IPC::Run3::run3 [ $self->bin_perl, "-MCPAN", "-e", $cpan_str ];
		die "Failure detected installing $name, stopping" if $?;

		# copy in any extras (like config files)
		if ( my $extras = $mod->{extra} ) {
			for my $f ( keys %$extras ) {
				my $from = $f;
				my $to   = File::Spec->catfile( $self->image_dir, $extras->{$f} );
				$self->_copy( $from => $to );
			}
		}
	}

        return 1;
}

sub remove_image {
	my $self  = shift;
	my $image = $self->{image_dir};
	if ( -d $image ) {
		$self->trace("Removing previous $image\n");
		File::Remove::remove( \1, $image );

	} else {
		$self->trace("No previous $image found\n");
	}
        return 1;
}





#####################################################################
# Support Methods

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

sub _extract_whole {
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

sub _init_dir {
	my $self = shift;
	my $dir  = shift;
	File::Path::mkpath($dir);
	for my $d ( qw/dmake mingw licenses links perl/ ) {
		File::Path::mkpath(File::Spec->catdir( $dir, $d ));
	}
	return 1;
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

sub trace {
        my $self = shift;
	print $_[0];
}

1;

__END__

=pod

=head1 NAME

Perl::Dist::Builder - Create win32 Perl installers

=head1 SYNOPSIS

Command line interface

  perldist vanilla.yml

Programmatic interface

  use Perl::Dist::Builder;
  my $pdb = Perl::Dist::Builder->new( 'vanilla.yml' );
  $pdb->remove_image;
  $pdb->build_all;

=head1 DESCRIPTION

I<Perl::Dist::Builder is alpha software.>

Perl::Dist::Builder uses a configuration file to automatically generate a
complete, standalone Perl distribution in a directory suitable for
bundling into an executable installer.  

Perl::Dist::Builder requires Perl and numerous modules.  See 
L<Perl::Dist::Bootstrap> for details on how to bootstrap a Perl 
environment suitable for building new Perl distributions.

=head1 CONFIGURATION FILE

To be documented after Perl::Dist::Builder is refactored.  See the config
files in L<Perl::Dist::Vanilla> and L<Perl::Dist::Strawberry> for current
examples.

Some sections currently have no effect.  

=head1 CREATING THE INSTALLER

Perl::Dist::Builder is not yet integrated with tools to create the
executable. Installers for Vanilla Perl, etc. have been created with the
free Inno Setup tool.

Inno Setup can be downloaded from jrsoftware.org:
L<http://www.jrsoftware.org/isinfo.php>

Inno Setup is configured with .iss files included in the distributions.

A future version of Perl::Dist::Builder may likely auto-generate the
.iss file.

=head1 METHODS

=head2 new

 my $pdb = Perl::Dist::Builder->new( $yaml_config_file );

Create a new builder object, initialized from a YAML configuration file.

=head2 build_all

 $pdb->build_all;

Runs all build tasks in order:  

=over

=item *

install_binaries

=item *

install_perl

=item *

install_modules

=item *

install_extras

=item *

install_from_cpan

=back 

Does I<not> delete the existing image directory.

=head2 install_binaries

 $pdb->install_binaries;

Downloads binary packages (e.g. compiler, dmake) from URLs provided in
the config file.  Unpacks them (or portions of them) into the image
directory.

=head2 install_from_cpan

 $pdb->install_from_cpan;

Uses the copy of perl in the image directory to run CPAN and install
modules defined in the config file.

=head2 install_extras

 $pdb->install_extras;

Copies local files into the image directory.  E.g. documentation, menu
shortcuts, CPAN starter config file, etc.

=head2 install_modules

 $pdb->install_modules;

Downloads tarballs for modules defined in the config file, unpacks them
and installs them directly using "Makefile.PL" and "dmake".  Does not
invoke CPAN. (Used primarily to get necessary prerequisite modules to
make CPAN work sanely and safely without binary helpers on Win32.)

=head2 install_perl

 $pdb->install_perl;

Downloads Perl source tarball, unpacks it, builds it, and installs it into
the image directory.

=head2 remove_image

 $pdb->remove_image;

Removes the "image_dir" directory specified in the config file, if
it exists, and prints a diagnostic message.

=head1 ROADMAP

Massive refactoring/rewrite is needed.  This initial version is a crudely
modulized form of individual perl scripts used in the early development
process of Vanilla Perl.

Additional documentation will be created after refactoring.

=head1 BUGS

Please report any bugs or feature using the CPAN Request Tracker.  
Bugs can be submitted by email to C<bug-Perl-Dist@rt.cpan.org> or 
through the web interface at 
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Perl-Dist>

=head1 AUTHOR

Adam Kennedy <adamk@cpan.org>

David A. Golden <dagolden@cpan.org>

=head1 COPYRIGHT

Copyright 2007 Adam Kennedy.

Copyright 2006 David A. Golden.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

=over

=item *

L<Perl::Dist>

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
