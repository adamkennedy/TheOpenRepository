package FBP::Control;

use Mouse;

our $VERSION = '0.16';

extends 'FBP::Window';

has default => (
	is  => 'ro',
	isa => 'Bool',
);

has permission => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
);

1;
