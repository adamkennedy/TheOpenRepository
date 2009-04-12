package ADAMK::Distribution::Checkout;

use 5.008;
use strict;
use warnings;
use Carp                   ();
use File::Spec             ();
use ADAMK::SVN             ();
use Module::Changes::ADAMK ();

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
# Integration with Module::Changes::ADAMK

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
		die('Changes file does not exist');
	}
	Module::Changes::ADAMK->read($file);
}





#####################################################################
# High Level Methods

sub update_current_release_datetime {
	my $self    = shift;
	my $changes = $self->changes;
	my $release = $changes->current_release;
	$release->set_datetime_now;
	$changes->save;
	return 1;
}

1;
