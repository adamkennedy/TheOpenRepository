package FBP::Button;

use Mouse;

our $VERSION = '0.07';

extends 'FBP::Window';
with    'FBP::Control';

has OnButtonClick => (
	is  => 'ro',
	isa => 'Str',
);

1;
