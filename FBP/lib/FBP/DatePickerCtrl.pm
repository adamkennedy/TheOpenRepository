package FBP::DatePickerCtrl;

use Mouse;

our $VERSION = '0.39';

extends 'FBP::Control';

has style => (
	is  => 'ro',
	isa => 'Str',
);

has OnDateChanged => (
	is  => 'ro',
	isa => 'Str',
);

no Mouse;
__PACKAGE__->meta->make_immutable;

1;
