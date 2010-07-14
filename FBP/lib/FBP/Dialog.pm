package FBP::Dialog;

use Mouse;

our $VERSION = '0.12';

extends 'FBP::Window';

has style => (
	is  => 'ro',
	isa => 'Str',
);

1;
