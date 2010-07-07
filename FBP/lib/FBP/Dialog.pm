package FBP::Dialog;

use Mouse;

our $VERSION = '0.07';

extends 'FBP::Window';

has style => (
	is  => 'ro',
	isa => 'Str',
);

1;
