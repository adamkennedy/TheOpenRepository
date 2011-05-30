package FBP::ComboBox;

use Mouse;

our $VERSION = '0.30';

extends 'FBP::ControlWithItems';

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
