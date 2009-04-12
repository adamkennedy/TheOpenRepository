package ADAMK::Shell;

use 5.008;
use strict;
use warnings;
use ADAMK::Repository ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.06';
}

use Object::Tiny 1.06 qw{
	root
	repository
};





#####################################################################
# Constructor

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);

	# Create the repository from the root
	$self->{repository} = ADAMK::Repository->new(
		root  => $self->root,
		trace => $self->{trace},
	);

	return $self;
}





#####################################################################
# Repository Commands

sub compare_tarball_latest {
	shift->repository->compare_tarball_latest(@_);
}

sub compare_tarball_stable {
	shift->repository->compare_tarball_stable(@_);
}

sub compare_export_latest {
	shift->repository->compare_export_latest(@_);
}

sub compare_export_stable {
	shift->repository->compare_export_stable(@_);
}





#####################################################################
# Custom Commands

sub update_current_release_datetime {
	my $self     = shift;
	my $dist     = $self->repository->distribution(shift);
	my $latest   = $dist->latest->version;
	my $checkout = $dist->checkout;
	my $current  = $checkout->changes->current->version;
	if ( $latest eq $current ) {
		# We have already released the current version
		die("Version $current has already been released");
	}
	my $date = $checkout->update_current_release_datetime;
	$checkout->svn_commit(
		-m => "[bot] Set version $current release date to $date",
		'Changes',
	);
}

1;
