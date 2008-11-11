package ADAMK::Release;

use 5.008;
use strict;
use warnings;
use Carp         'croak';
use Params::Util qw{ _INSTANCE };

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}

use Object::Tiny qw{
	file
	directory
	path
	repository
	distribution
	version
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

1;
