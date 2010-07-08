package FBP::Button;

use Mouse;

our $VERSION = '0.08';

extends 'FBP::Window';
with    'FBP::Control';

has OnButtonClick => (
	is  => 'ro',
	isa => 'Str',
);

1;
