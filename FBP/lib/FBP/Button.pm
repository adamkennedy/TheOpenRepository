package FBP::Button;

use Mouse;

our $VERSION = '0.26';

extends 'FBP::Control';

has label => (
	is  => 'ro',
	isa => 'Str',
);

has OnButtonClick => (
	is  => 'ro',
	isa => 'Str',
);

1;
