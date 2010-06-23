package FBP::Dialog;

use Moose;

our $VERSION = '0.04';

extends 'FBP::Window';

has style => (
	is  => 'ro',
	isa => 'Str',
);

1;
