package FBP::CustomControl;

use Mouse;

our $VERSION = '0.23';

extends 'FBP::Window';

has class => (
	is  => 'ro',
	isa => 'Str',
);

has declaration => (
	is  => 'ro',
	isa => 'Str',
);

has construction => (
	is  => 'ro',
	isa => 'Str',
);

has include => (
	is  => 'ro',
	isa => 'Str',
);

has settings => (
	is  => 'ro',
	isa => 'Str',
);

1;
