package FBP::BitmapButton;

use Mouse;

our $VERSION = '0.30';

extends 'FBP::Button';

has bitmap => (
	is  => 'ro',
	isa => 'Str',
);

has disabled => (
	is  => 'ro',
	isa => 'Str',
);

has selected => (
	is  => 'ro',
	isa => 'Str',
);

has focus => (
	is  => 'ro',
	isa => 'Str',
);

has hover => (
	is  => 'ro',
	isa => 'Str',
);

1;
