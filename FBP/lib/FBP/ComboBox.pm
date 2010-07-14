package FBP::ComboBox;

use Mouse;

our $VERSION = '0.12';

extends 'FBP::Window';
with    'FBP::Control';

has value => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
	default  => '',
);

has style => (
	is  => 'ro',
	isa => 'Str',
);

has OnComboBox => (
	is  => 'ro',
	isa => 'Str',
);

has OnText => (
	is  => 'ro',
	isa => 'Str',
);

has OnTextEnter => (
	is  => 'ro',
	isa => 'Str',
);

1;
