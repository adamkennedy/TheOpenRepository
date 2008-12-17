package ADAMK::Release;

use 5.008;
use strict;
use warnings;
use Carp             'croak';
use File::Temp       ();
use File::Remove     ();
use Params::Util     qw{ _INSTANCE };
use Archive::Extract ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.04';
}

use Object::Tiny qw{
	file
	directory
	path
	repository
	distribution
	version
	extracted
};





#####################################################################
# Constructor

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);

	# Check params
	unless ( _INSTANCE($self->repository, 'ADAMK::Repository') ) {
		croak("Did not provide a repository");
	}

	return $self;
}

sub stable {
	!! ($_[0]->version !~ /_/);
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

sub extract {
	my $self = shift;
	my $temp = File::Temp::tempdir(@_);
	my $ae   = Archive::Extract->new(
		archive => $self->path,
	);
	my $ok   = $ae->extract( to => $temp );
	croak( 
		"Failed to extract " . $self->path
		. ": " . $ae->error
	) unless $ok;
	$self->{extracted} = $ae->extract_path;
	return $self->{extracted};
}

sub clear {
	my $self = shift;
	if ( $self->extracted ) {
		delete $self->{extracted};
	}
	return 1;
}

1;
