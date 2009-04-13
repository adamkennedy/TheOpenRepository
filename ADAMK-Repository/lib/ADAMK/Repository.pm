package ADAMK::Repository;

=pod

=head1 NAME

ADAMK::Repository - Repository object model for ADAMK's svn repository

=cut

use 5.008;
use strict;
use warnings;
use Carp                        ();
use List::Util             1.18 ();
use File::Spec             3.29 ();
use File::Temp             0.21 ();
use File::Flat             1.04 ();
use File::pushd            1.00 ();
use File::Remove           1.42 ();
use File::Find::Rule       0.30 ();
use File::Find::Rule::VCS  1.05 ();
use File::Find::Rule::Perl 1.05 ();
use IPC::Run3             0.034 ();
use Archive::Extract       0.30 ();
use Params::Util           0.35 ();
use CPAN::Version           5.5 ();
use Object::Tiny::XS       1.01 ();
use PPI                   1.203 ();
use Module::Changes::ADAMK 0.04 ();
use ADAMK::Release              ();
use ADAMK::Distribution         ();
use ADAMK::Role::SVN            ();
use ADAMK::Mixin::Trace;

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '0.07';
	@ISA     = 'ADAMK::Role::SVN';
}





#####################################################################
# Constructor

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Check params
	unless ( -d $self->svn_root($self->root) ) {
		Carp::croak("Missing or invalid SVN root directory");
	}
	if ( $self->{trace} and not Params::Util::_CODE($self->{trace}) ) {
		$self->{trace} = sub { print @_ };
	}
	$self->{preload} = !! $self->{preload};

	# Preload if we are into that sort of thing
	$self->trace("Preloading distributions...\n");
	$self->{distributions} = [ $self->distributions ];
	$self->trace("Preloading releases...\n");
	$self->{releases} = [ $self->releases ];

	return $self;
}

sub root {
	$_[0]->{root};
}

sub dir {
	File::Spec->catdir( shift->root, @_ );
}

sub file {
	File::Spec->catfile( shift->root, @_ );
}





#####################################################################
# Distributions

sub distribution_dir {
	$_[0]->dir('trunk');
}

sub distribution_directories {
	my $self = shift;

	# Load the directory
	local *DIR;
	opendir( DIR, $self->distribution_dir ) or die("opendir: $!");
	my @files = sort readdir(DIR);
	closedir(DIR) or die("closedir: $!");

	# Filter the directory
	return grep {
		/^[A-Z][A-Z0-9]*(?:-[A-Z][A-Z0-9]*)*$/i
	} @files;
}

sub distributions {
	my $self = shift;

	# Use cache if preloaded
	if ( $self->{distributions} ) {
		return @{$self->{distributions}};
	}

	my @directories   = $self->distribution_directories;
	my @distributions = ();
	foreach my $directory ( @directories ) {
		my $object = ADAMK::Distribution->new(
			name       => $directory,
			directory  => 'trunk',
			repository => $self,
			path       => File::Spec->catfile(
				$self->distribution_dir, $directory,
			),
		);
		push @distributions, $object;
	}
	return @distributions;
}

sub distribution {
	my @distribution = grep {
		$_->name eq $_[1]
	} $_[0]->distributions;
	return $distribution[0];
}





#####################################################################
# Releases

sub release_dir {
	$_[0]->dir('releases');
}

sub release_files {
	my $self   = shift;
	local *DIR;
	opendir( DIR, $self->release_dir ) or die("opendir: $!");
	my @files = sort readdir(DIR);
	closedir(DIR) or die("closedir: $!");
	return grep { /^([\w-]+?)-(\d[\d_\.]*[a-z]?)\.(?:tar\.gz|zip)$/ } @files;
}

sub releases {
	my $self = shift;

	# Use cache if preloaded
	if ( $self->{releases} ) {
		return @{$self->{releases}};
	}

	my @files    = $self->release_files;
	my @releases = ();
	foreach my $file ( @files ) {
		unless ( $file =~ /^([\w-]+?)-(\d[\d_\.]*[a-z]?)\.(?:tar\.gz|zip)$/ ) {
			Carp::croak("Unexpected file name '$file'");
		}
		my $distname = "$1";
		my $version  = "$2";
		my $object = ADAMK::Release->new(
			repository => $self,
			directory  => 'releases',
			file       => $file,
			version    => $version,
			distname   => $distname,
			path       => File::Spec->catfile(
				$self->release_dir, $file,
			),
		);
		push @releases, $object;
	}

	return @releases;
}

# Releases for distributions currently on the trunk
sub releases_trunk {
	grep { $_->trunk } $_[0]->releases;
}

sub release_latest {
	$_[0]->distribution($_[1])->latest;
}

sub release_version {
	$_[0]->distribution($_[1])->release($_[2]);
}





#####################################################################
# Comparison

sub araxis_compare_bin {
	return 'C:\\Program Files\\Araxis\\Araxis Merge\\Compare.exe';
}

sub araxis_compare {
	my $self  = shift;
	my $left  = shift;
	my $right = shift;
	unless ( -d $left ) {
		Carp::croak("Left directory does not exist");
	}
	unless ( -d $right ) {
		Carp::croak("Right directory does not exist");
	}
	IPC::Run3::run3( [
		$self->araxis_compare_bin,
		$left,
		$right,
	] );
}

sub compare_tarball_latest {
	my $self         = shift;
	my $distribution = $self->distribution($_[0]);
	my $release      = $distribution->latest;
	unless ( $distribution ) {
		Carp::croak("Failed to find distribution $_[0]");
	}
	unless ( $release ) {
		Carp::croak("Failed to find latest release for $_[0]");
	}

	# Launch the comparison
	$self->araxis_compare(
		$release->extract,
		$distribution->path,
	);
}

sub compare_tarball_stable {
	my $self         = shift;
	my $distribution = $self->distribution($_[0]);
	my $release      = $distribution->stable;
	unless ( $distribution ) {
		Carp::croak("Failed to find distribution $_[0]");
	}
	unless ( $release ) {
		Carp::croak("Failed to find latest release for $_[0]");
	}

	# Launch the comparison
	$self->araxis_compare(
		$release->extract,
		$distribution->path,
	);
}

sub compare_export_latest {
	my $self         = shift;
	my $distribution = $self->distribution($_[0]);
	my $release      = $distribution->latest;
	unless ( $distribution ) {
		Carp::croak("Failed to find distribution $_[0]");
	}
	unless ( $release ) {
		Carp::croak("Failed to find latest release for $_[0]");
	}

	# Launch the comparison
	$self->araxis_compare(
		$release->export,
		$distribution->path,
	);
}

sub compare_export_stable {
	my $self         = shift;
	my $distribution = $self->distribution($_[0]);
	my $release      = $distribution->stable;
	unless ( $distribution ) {
		Carp::croak("Failed to find distribution $_[0]");
	}
	unless ( $release ) {
		Carp::croak("Failed to find latest release for $_[0]");
	}

	# Launch the comparison
	$self->araxis_compare(
		$release->export,
		$distribution->path,
	);
}





#####################################################################
# SVN Methods

sub svn_dir {
	my $self = shift;
	my $dir  = shift;
	unless ( defined Params::Util::_STRING($dir) ) {
		return undef;
	}
	my $path = File::Spec->catfile( $self->root, $dir );
	unless ( -d $path ) {
		return undef;
	}
	unless ( -d File::Spec->catdir($path, '.svn') ) {
		return undef;
	}
	return $dir;
}

sub svn_file {
	my $self = shift;
	my $file = shift;
	unless ( defined Params::Util::_STRING($file) ) {
		return undef;
	}
	my $path = File::Spec->catfile( $self->root, $file );
	unless ( -f $path ) {
		return undef;
	}
	my ($v, $d, $f) = File::Spec->splitpath($path);
	my $svn = File::Spec->catpath(
		$v,
		File::Spec->catdir($d, '.svn', 'text-base'),
		"$f.svn-base",
	);
	unless ( -f $svn ) {
		return undef;
	}
	return $file;
}

sub svn_dir_info {
	my $self = shift;
	my $dir  = $self->svn_dir(shift);
	unless ( defined $dir ) {
		return undef;
	}
	my $hash = $self->svn_info($dir);
	$hash->{Directory} = $dir;
	return $hash;
}

sub svn_file_info {
	my $self = shift;
	my $file = $self->svn_file(shift);
	unless ( defined $file ) {
		return undef;
	}
	my $hash = $self->svn_info($file);
	return $hash;
}

sub svn_checkout {
	my $self = shift;
	my $url  = shift;
	my $path = shift;
	my @rv   = $self->svn_command(
		'checkout', $url, $path,
	);
	unless ( $rv[-1] =~ qr/^Checked out revision \d+\.$/ ) {
		die "Failed to checkout '$url'";
	}
	return 1;
}

sub svn_export {
	my $self     = shift;
	my $url      = shift;
	my $path     = shift;
	my $revision = shift;
	my @rv       = $self->svn_command(
		'export', '--force', '-r', $revision, $url, $path,
	);
	unless ( $rv[-1] eq "Exported revision $revision." ) {
		die "Failed to export '$url' at revision $revision";
	}
	return 1;
}

1;

=pod

=head1 SUPPORT

No support is available for this module

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2007 - 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
