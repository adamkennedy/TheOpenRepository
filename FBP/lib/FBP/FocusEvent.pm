package FBP::FocusEvent;

use Mouse::Role;

our $VERSION = '0.12';

has OnKillFocus => (
	is  => 'ro',
	isa => 'Str',
);

has OnSetFocus => (
	is  => 'ro',
	isa => 'Str',
);

1;
