package ADAMK::Shell;

use 5.008;
use strict;
use warnings;
use ADAMK::Repository ();

use Object::Tiny::XS qw{
	repository
};

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '0.09';
	@ISA     = qw{
		ADAMK::Role::Trace
		ADAMK::Role::File
	};
}





#####################################################################
# Constructor

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Create the repository from the root
	$self->{repository} = ADAMK::Repository->new(
		path  => $self->path,
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

sub info {
	my $self    = shift;
	my $dist    = $self->repository->distribution(shift);
	my $release = $dist->latest;
	print "Distribution: "    . $dist->name . "\n";
	print "Directory:    "    . $dist->path . "\n";
	print "Changes Version: " . $dist->changes->current->version . "\n";
	print "Release Version: " . $release->version . "\n";
}

sub update_current_release_datetime {
	my $self         = shift;
	my $distribution = $self->repository->distribution(shift);

	# Is there an unreleased version
	my $checkout     = $distribution->checkout;
	my $released     = $distribution->latest->version;
	my $current      = $checkout->changes->current->version;
	if ( $released eq $current ) {
		# We have already released the current version
		die("Version $current has already been released");
	}

	# Update the Changes file
	my $date = $checkout->update_current_release_datetime;

	# Commit if we are allowed
	$checkout->svn_commit(
		-m => "[bot] Set version $current release date to $date",
		'Changes',
	);
}

sub update_current_perl_versions {
	my $self         = shift;
	my $distribution = $self->repository->distribution(shift);

	# Is there an unreleased version
	my $checkout     = $distribution->checkout;
	my $released     = $distribution->latest->version;
	my $current      = $checkout->changes->current->version;
	if ( $released eq $current ) {
		# We have already released the current version
		die("Version $current has already been released");
	}

	# Update the $VERSION strings
	my $changed = $checkout->update_current_perl_versions;
	unless ( $changed ) {
		$self->trace("No files were updated");
	}

	# Commit if we are allowed
	$checkout->svn_commit(
		-m => "[bot] Changed \$VERSION strings from $released to $current",
	);
}

1;
