package FBP::SpinCtrl;

use Mouse;

our $VERSION = '0.21';

extends 'FBP::Control';

has value => (
	is  => 'ro',
	isa => 'Str',
);

has min => (
	is  => 'ro',
	isa => 'Str',
);

has max => (
	is  => 'ro',
	isa => 'Str',
);

has initial => (
	is  => 'ro',
	isa => 'Str',
);

has style => (
	is  => 'ro',
	isa => 'Str',
);

1;
