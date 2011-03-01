package FBP::DirPickerCtrl;

use Mouse;

our $VERSION = '0.20';

extends 'FBP::Control';

has value => (
	is  => 'ro',
	isa => 'Str',
);

has message => (
	is  => 'ro',
	isa => 'Str',
);

has OnDirChanged => (
	is  => 'ro',
	isa => 'Str',
);

1;
