package FBP::Button;

use Mouse;

our $VERSION = '0.33';

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
