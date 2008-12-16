package ADAMK::Distribution;

use 5.008;
use strict;
use warnings;

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.03';
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

1;
