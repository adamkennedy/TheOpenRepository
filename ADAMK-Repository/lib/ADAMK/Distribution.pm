package ADAMK::Distribution;

use 5.008;
use strict;
use warnings;
use File::Spec                    ();
use File::Temp                    ();
use File::pushd                   ();
use CPAN::Version                 ();
use ADAMK::Util                   'shell';
use ADAMK::Distribution::Export   ();
use ADAMK::Distribution::Checkout ();

use Object::Tiny::XS qw{
	name
	directory
	path
	repository
};

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.07';
}





#####################################################################
# Constructor

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);

	# Param checking

	return $self;
}






#####################################################################
# SVN Integration

sub svn_info {
	$_[0]->repository->svn_dir_info(
		File::Spec->catdir(
			$_[0]->directory,
			$_[0]->name,
		)
	);
}

sub svn_last_changed {
	$_[0]->svn_info->{LastChangedRev};
}

sub svn_url {
	$_[0]->svn_info->{URL};
}

sub checkout {
	my $self = shift;
	my $path = File::Temp::tempdir(@_);
	my $url  = $self->svn_url;
	$self->repository->svn_checkout( $url, $path );

	# Create and return an ADAMK::Distribution::Checkout object
	return ADAMK::Distribution::Checkout->new(
		name         => $self->name,
		path         => $path,
		trace        => $self->repository->{trace},
		distribution => $self,
	);
}

sub export {
	my $self     = shift;
	my $revision = shift;
	my $path     = File::Temp::tempdir(@_);
	my $url      = $self->svn_url;
	$self->repository->svn_export( $url, $path, $revision );

	# Create and return an ADAMK::Distribution::Export object
	return ADAMK::Distribution::Export->new(
		name         => $self->name,
		path         => $path,
		distribution => $self,
	);
}

sub export_head {
	$_[0]->export('HEAD');
}





#####################################################################
# Releases

sub releases {
	my $self     = shift;
	my @releases = sort {
		CPAN::Version->vcmp( $b->version, $a->version )
	} grep {
		$_->distname eq $self->name
	} $self->repository->releases;
	return @releases;
}

sub release {
	my $self     = shift;
	my @releases = grep {
		$_->version eq $_[0]
	} $self->releases;
	return $releases[0];
}

sub latest {
	my $self     = shift;
	my @releases = $self->releases;
	return $releases[0];
}

sub stable {
	my $self     = shift;
	my @releases = grep { $_->stable } $self->releases;
	return $releases[0];
}





#####################################################################
# Module::Changes::ADAMK Integration

sub changes_file {
	my $self = shift;
	File::Spec->catfile(
		$self->path,
		'Changes',
	);
}

sub changes {
	my $self = shift;
	my $file = $self->changes_file;
	unless ( -f $file ) {
		my $name = $self->name;
		die("Changes file '$file' in '$name' does not exist");
	}
	Module::Changes::ADAMK->read($file);
}

1;
