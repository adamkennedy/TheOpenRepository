package FBP::KeyEvent;

use Mouse::Role;

our $VERSION = '0.36';

has OnChar => (
	is  => 'ro',
	isa => 'Str',
);

has OnKeyDown => (
	is  => 'ro',
	isa => 'Str',
);

has OnKeyUp => (
	is  => 'ro',
	isa => 'Str',
);

no Mouse::Role;

1;
