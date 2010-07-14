package FBP::CheckBox;

use Mouse;

our $VERSION = '0.12';

extends 'FBP::Window';
with    'FBP::Control';

has OnCheckBox => (
	is  => 'ro',
	isa => 'Str',
);

1;
