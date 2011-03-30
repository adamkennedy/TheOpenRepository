package FBP::Control;

use Mouse;

our $VERSION = '0.25';

extends 'FBP::Window';

has default => (
	is  => 'ro',
	isa => 'Bool',
);

1;
