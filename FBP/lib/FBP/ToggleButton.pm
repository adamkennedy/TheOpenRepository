package FBP::ToggleButton;

use Mouse;

our $VERSION = '0.33';

extends 'FBP::Control';

has label => (
	is  => 'ro',
	isa => 'Str',
);

has value => (
	is  => 'ro',
	isa => 'Bool',
);

has OnToggleButton => (
	is  => 'ro',
	isa => 'Str',
);

1;
