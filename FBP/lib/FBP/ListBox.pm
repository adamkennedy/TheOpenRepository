package FBP::ListBox;

use Mouse;

our $VERSION = '0.32';

extends 'FBP::ControlWithItems';

has style => (
	is  => 'ro',
	isa => 'Str',
);

has OnListBox => (
	is  => 'ro',
	isa => 'Str',
);

has OnListDClick => (
	is  => 'ro',
	isa => 'Str',
);

1;
