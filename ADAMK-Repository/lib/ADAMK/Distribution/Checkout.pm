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
		my $name = $self->name;
		die("Changes file '$file' in '$name' does not exist");
	}
	Module::Changes::ADAMK->read($file);
}





#####################################################################
# High Level Methods

sub update_current_release_datetime {
	my $self    = shift;
	my $changes = $self->changes;
	my $release = $changes->current;
	$release->set_datetime_now;
	my $version = $release->version;
	my $date    = $release->date;
	$self->trace("Set version $version release date to $date\n");
	$changes->save;
	return $date;
}

1;
