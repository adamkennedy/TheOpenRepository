package FBP::ListBox;

use Mouse;

our $VERSION = '0.12';

extends 'FBP::Window';
with    'FBP::Control';

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
