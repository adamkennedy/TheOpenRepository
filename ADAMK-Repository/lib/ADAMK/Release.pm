package ADAMK::Release;

use 5.008;
use strict;
use warnings;
use Carp             ();
use File::Temp       ();
use File::Remove     ();
use Params::Util     qw{ _INSTANCE };
use Archive::Extract ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.07';
}

use Object::Tiny qw{
	file
	directory
	path
	repository
	distname
	version
	extracted
	exported
};





#####################################################################
# Constructor

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);

	# Check params
	unless ( _INSTANCE($self->repository, 'ADAMK::Repository') ) {
		Carp::croak("Did not provide a repository");
	}

	return $self;
}

sub stable {
	!! ($_[0]->version !~ /_/);
}

sub distribution {
	$_[0]->repository->distribution($_[0]->distname);
}

sub trunk {
	!! $_[0]->distribution;
}





#####################################################################
# SVN Integration

sub svn_info {
	$_[0]->repository->svn_file_info(
		File::Spec->catfile(
			$_[0]->directory,
			$_[0]->file,
		)
	);
}

sub svn_revision {
	$_[0]->svn_info->{LastChangedRev};
}





#####################################################################
# Extraction

# Extracts the actual tarball into a temporary directory
sub extract {
	my $self = shift;
	my $temp = File::Temp::tempdir(@_);
	my $ae   = Archive::Extract->new(
		archive => $self->path,
	);
	my $ok   = $ae->extract( to => $temp );
	Carp::croak( 
		"Failed to extract " . $self->path
		. ": " . $ae->error
	) unless $ok;
	$self->{extracted} = $ae->extract_path;
	return $self->{extracted};
}

# Exports the distribution at the point in time that the
# release was created.
sub export {
	my $self = shift;
	unless ( $self->trunk ) {
		die(
			"Cannot export non-trunk release " .
			$self->file
		);
	}
	$self->distribution->export( $self->svn_revision, @_ );
}

sub clear {
	delete $_[0]->{extracted} if $_[0]->{extracted};
	delete $_[0]->{exported}  if $_[0]->{exported};
	return 1;
}

1;
