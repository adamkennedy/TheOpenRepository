package FBP::Control;

use Mouse::Role;

our $VERSION = '0.10';

has default => (
	is  => 'ro',
	isa => 'Bool',
);

1;
