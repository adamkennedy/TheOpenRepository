package FBP::Button;

use Moose;

our $VERSION = '0.02';

extends 'FBP::Window';

has default => (
	is  => 'ro',
	isa => 'Bool',
);

1;
