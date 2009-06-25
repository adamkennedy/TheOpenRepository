package ADAMK::Repository;

=pod

=head1 NAME

ADAMK::Repository - Repository object model for ADAMK's svn repository

=cut

use 5.008;
use strict;
use warnings;
use Carp                          ();
use List::Util               1.18 ();
use Params::Util             0.35 qw{ _REGEX _INSTANCE };
use File::Spec               3.29 ();
use File::Temp               0.21 ();
use File::Flat               1.04 ();
use File::pushd              1.00 ();
use File::Remove             1.42 ();
use File::HomeDir            0.86 ();
use File::ShareDir           1.00 ();
use File::Find::Rule         0.30 ();
use File::Find::Rule::VCS    1.05 ();
use File::Find::Rule::Perl   1.06 ();
use XML::Tiny                2.02 ();
use YAML::Tiny               1.37 ();
use Object::Tiny::XS         1.01 ();
use Text::Table             1.114 ();
use IPC::Run3               0.034 ();
use IO::ScalarArray         2.110 ();
use Class::XSAccessor        0.14 ();
use Parse::CPAN::Meta        0.03 ();
use Perl::Version           1.009 ();
use CPAN::Version             5.5 ();
use JSON                     2.14 ();
use Archive::Extract         0.30 ();
use ExtUtils::MakeMaker      6.50 ();
use PPI                     1.203 ();
use ORLite::Migrate          0.03 ();
use Module::Changes::ADAMK   0.10 ();
use ADAMK::Util                   ();
use ADAMK::Cache                  ();
use ADAMK::Version                ();
use ADAMK::SVN::Log               ();
use ADAMK::SVN::Info              ();
use ADAMK::Role::Trace            ();
use ADAMK::Role::File             ();
use ADAMK::Role::SVN              ();
use ADAMK::Role::Changes          ();
use ADAMK::Role::Make             ();
use ADAMK::Release                ();
use ADAMK::Release::Extract       ();
use ADAMK::Distribution           ();
use ADAMK::Distribution::Export   ();
use ADAMK::Distribution::Checkout ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '0.11';
	@ISA     = qw{
		ADAMK::Role::Trace
		ADAMK::Role::File
		ADAMK::Role::SVN
	};
}





#####################################################################
# Constructor

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Check params
	unless ( $self->svn_dir($self->path) ) {
		Carp::croak("Missing or invalid SVN root directory");
	}
	$self->{preload} = !! $self->{preload};

	# Preload if we are into that sort of thing
	if ( $self->{preload} ) {
		$self->trace("Preloading releases...\n");
		$self->{releases} = [ $self->releases ];
		$self->trace("Preloading distributions...\n");
		$self->{distributions} = [ $self->distributions ];
	}

	return $self;
}






#####################################################################
# Distributions

sub directories {
	my $self = shift;

	# Load the directory
	local *DIR;
	opendir( DIR, $self->dir('trunk') ) or die("opendir: $!");
	my @files = sort readdir(DIR);
	closedir(DIR) or die("closedir: $!");

	# Filter the directory
	return grep {
		/^[A-Z][A-Z0-9]*(?:-[A-Z][A-Z0-9]*)*$/i
	} @files;
}

sub distribution {
	my @distribution = grep {
		$_->name eq $_[1]
	} $_[0]->distributions;
	return $distribution[0];
}

sub distributions {
	my $self = shift;

	# Use cache if preloaded
	if ( $self->{distributions} ) {
		return @{$self->{distributions}};
	}

	my @directories   = $self->directories;
	my @distributions = ();
	foreach my $directory ( @directories ) {
		my $object = ADAMK::Distribution->new(
			name       => $directory,
			path       => $self->dir('trunk', $directory),
			repository => $self,
		);
		push @distributions, $object;
	}

	return @distributions;
}

sub distributions_like {
	my $self = shift;
	unless ( defined $_[0] ) {
		die "Did not provide a like condition";
	}
	my $like = _REGEX($_[0]) ? $_[0] : quotemeta($_[0]);
	return grep {
		$_->name =~ /$like/
	} $self->distributions;	
}

sub distributions_released {
	my $self = shift;
	if ( @_ ) {
		return grep {
			scalar $_->releases
		} $self->distributions_like(@_);
	} else {
		return grep {
			scalar $_->releases
		} $self->distributions;
	}
}

sub distributions_unreleased {
	my $self = shift;
	if ( @_ ) {
		return grep {
			not scalar $_->releases
		} $self->distributions_like(@_);
	} else {
		return grep {
			not scalar $_->releases
		} $self->distributions;
	}
}





#####################################################################
# Releases

sub tarballs {
	my $self   = shift;
	local *DIR;
	opendir( DIR, $self->dir('releases') ) or die("opendir: $!");
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

	my @files    = $self->tarballs;
	my @releases = ();
	foreach my $file ( @files ) {
		unless ( $file =~ /^([\w-]+?)-(\d[\d_\.]*[a-z]?)\.(?:tar\.gz|zip)$/ ) {
			Carp::croak("Unexpected file name '$file'");
		}
		my $distname = "$1";
		my $version  = "$2";
		my $object = ADAMK::Release->new(
			file       => $file,
			directory  => $self->file('releases'),
			path       => $self->file('releases', $file),
			distname   => $distname,
			version    => $version,
			repository => $self,
		);
		push @releases, $object;
	}

	return @releases;
}





#####################################################################
# SVN Methods

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





#####################################################################
# Comparison

sub araxis_compare_bin {
	return 'C:\\Program Files\\Araxis\\Araxis Merge\\Compare.exe';
}

sub araxis_compare {
	my $self  = shift;
	my $left  = shift;
	my $right = shift;
	if ( _INSTANCE($left, 'ADAMK::Role::File') ) {
		$left = $left->directory;
	}
	if ( _INSTANCE($right, 'ADAMK::Role::File') ) {
		$right = $right->directory;
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
		$release->extract( CLEANUP => 0 ),
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
		$release->extract( CLEANUP => 0 ),
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
		$release->export( CLEANUP => 0 ),
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
		$release->export( CLEANUP => 0 ),
		$distribution->path,
	);
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
