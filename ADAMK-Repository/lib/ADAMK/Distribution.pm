package ADAMK::Distribution;

use 5.008;
use strict;
use warnings;
use File::Spec        ();
use File::Temp        ();
use File::pushd       ();
use CPAN::Version     ();
use ADAMK::Repository ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '0.09';
	@ISA     = qw{
		ADAMK::Role::File
		ADAMK::Role::SVN
		ADAMK::Role::Changes
		ADAMK::Role::Make
	};
}

use Class::XSAccessor
	getters => {
		name       => 'name',
		repository => 'repository',
	};





#####################################################################
# Constructor

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;
	return $self;
}






#####################################################################
# SVN Integration

sub checkout {
	my $self = shift;
	my $path = File::Temp::tempdir(@_);
	my $url  = $self->svn_url;
	$self->repository->svn_checkout( $url, $path );

	# Create and return an ADAMK::Distribution::Checkout object
	return ADAMK::Distribution::Checkout->new(
		name         => $self->name,
		path         => $path,
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

1;
