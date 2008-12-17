package ADAMK::Distribution;

use 5.008;
use strict;
use warnings;
use File::Spec    ();
use File::Temp    ();
use CPAN::Version ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.04';
}

use Object::Tiny qw{
	name
	directory
	path
	repository
	distribution
};





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

sub export {
	my $self     = shift;
	my $revision = shift;

	# Create a temp directory to export to
	
}




#####################################################################
# Releases

sub releases {
	my $self     = shift;
	my @releases = sort {
		CPAN::Version->vcmp( $b, $a )
	} grep {
		$_->distribution eq $self->distribution
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
# Comparison

sub compare_revision {
	my $self = shift;

	# Find the release
}

1;
