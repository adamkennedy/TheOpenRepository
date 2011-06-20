package FBP::ColourPickerCtrl;

use Mouse;

our $VERSION = '0.32';

extends 'FBP::Control';

has colour => (
	is  => 'ro',
	isa => 'Str',
);

has style => (
	is  => 'ro',
	isa => 'Str',
);

has OnColourChanged => (
	is  => 'ro',
	isa => 'Str',
);

1;
