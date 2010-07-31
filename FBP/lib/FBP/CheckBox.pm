package FBP::CheckBox;

use Mouse;

our $VERSION = '0.13';

extends 'FBP::Window';
with    'FBP::Control';

has OnCheckBox => (
	is  => 'ro',
	isa => 'Str',
);

1;
