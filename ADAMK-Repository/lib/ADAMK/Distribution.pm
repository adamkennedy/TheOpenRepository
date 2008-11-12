package ADAMK::Distribution;

use 5.008;
use strict;
use warnings;

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.02';
}

use Object::Tiny qw{
	path
	name
	repository
};






#####################################################################
# Constructor

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);

	

	return $self;
}

1;
