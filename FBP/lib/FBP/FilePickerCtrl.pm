package FBP::FilePickerCtrl;

use Mouse;

our $VERSION = '0.26';

extends 'FBP::Control';

has value => (
	is  => 'ro',
	isa => 'Str',
);

has message => (
	is  => 'ro',
	isa => 'Str',
);

has wildcard => (
	is  => 'ro',
	isa => 'Str',
);

has style => (
	is  => 'ro',
	isa => 'Str',
);

has OnFileChanged => (
	is  => 'ro',
	isa => 'Str',
);

1;
