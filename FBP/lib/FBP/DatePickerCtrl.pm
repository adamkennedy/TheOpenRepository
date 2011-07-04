package FBP::DatePickerCtrl;

use Mouse;

our $VERSION = '0.34';

extends 'FBP::Control';

has style => (
	is  => 'ro',
	isa => 'Str',
);

has OnDateChanged => (
	is  => 'ro',
	isa => 'Str',
);

1;
