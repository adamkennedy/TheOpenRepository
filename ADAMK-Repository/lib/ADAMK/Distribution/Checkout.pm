package ADAMK::Distribution::Checkout;

use 5.008;
use strict;
use warnings;
use Carp       ();
use ADAMK::SVN ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '0.06';
	@ISA     = 'ADAMK::SVN';
}

use Object::Tiny qw{
	path
	name
	distribution
};

sub root {
	$_[0]->path;
}

sub repository {
	$_[0]->distribution->repository;
}





#####################################################################
# SVN Integration

sub svn_revision {
	$_[0]->svn_info->{LastChangedRev};
}





#####################################################################
# SVN Methods

sub commit {
	my $self = shift;
	$self->repository->svn_commit(
		$self->path,
	);
}

1;
