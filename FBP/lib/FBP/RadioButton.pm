package FBP::RadioButton;

use Mouse;

our $VERSION = '0.34';

extends 'FBP::Control';

has label => (
	is  => 'ro',
	isa => 'Str',
);

has style => (
	is  => 'ro',
	isa => 'Str',
);

has value => (
	is  => 'ro',
	isa => 'Bool',
);

1;
