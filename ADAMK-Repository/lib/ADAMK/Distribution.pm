package ADAMK::Distribution;

use 5.008;
use strict;
use warnings;
use List::Util        ();
use File::Spec        ();
use File::Temp        ();
use File::pushd       ();
use CPAN::Version     ();
use ADAMK::Repository ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '0.12';
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

sub trace {
	shift->repository->trace(@_);
}




#####################################################################
# SVN Integration

sub checkout {
	my $self   = shift;
	my @params = @_ ? @_ : ( CLEANUP => 1 );
	my $path   = File::Temp::tempdir( @params );
	my $url    = $self->info->url;
	$self->repository->svn_checkout( $url, $path );

	# Create and return an ADAMK::Distribution::Checkout object
	ADAMK::Distribution::Checkout->new(
		name         => $self->name,
		path         => $path,
		distribution => $self,
	);
}

sub export {
	my $self     = shift;
	my $revision = shift;
	my @params   = @_ ? @_ : ( CLEANUP => 1 );
	my $path     = File::Temp::tempdir( @params );
	my $url      = $self->info->url;
	$self->repository->svn_export( $url, $path, $revision );

	# Create and return an ADAMK::Distribution::Export object
	ADAMK::Distribution::Export->new(
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
	List::Util::first { $_->version eq $_[1] } $_[0]->releases;
}

sub latest {
	($_[0]->releases)[0];
}

sub stable {
	List::Util::first { $_->stable } $_[0]->releases;
}

sub oldest {
	($_[0]->releases)[-1];
}

sub oldest_stable {
	List::Util::first { $_->stable } reverse $_[0]->releases;
}





#####################################################################
# ORDB::CPAN Integration

sub uploads {
	require ORDB::CPANUploads;
	ORDB::CPANUploads->import;
	ORDB::CPANUploads::Uploads->select('where dist = ? order by released desc', $_[0]->name);
}

sub maintainer {
	my @upload = $_[0]->uploads;
	@upload ? lc($upload[0]->author . '@cpan.org') : '';
}

sub mine {
	$_[0]->maintainer eq 'adamk@cpan.org'
}

1;
