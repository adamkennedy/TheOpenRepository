package FBP::Button;

use Mouse;

our $VERSION = '0.14';

extends 'FBP::Window';
with    'FBP::Control';

has label => (
	is  => 'ro',
	isa => 'Str',
);

has OnButtonClick => (
	is  => 'ro',
	isa => 'Str',
);

1;
