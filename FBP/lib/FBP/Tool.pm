package FBP::Tool;

use Mouse;

our $VERSION = '0.31';

extends 'FBP::Object';





######################################################################
# Properties

has id => (
	is  => 'ro',
	isa => 'Str',
);

has name => (
	is  => 'ro',
	isa => 'Str',
);

has label => (
	is  => 'ro',
	isa => 'Str',
);

has bitmap => (
	is  => 'ro',
	isa => 'Str',
);

has kind => (
	is  => 'ro',
	isa => 'Str',
);

has tooltip => (
	is  => 'ro',
	isa => 'Str',
);

has statusbar => (
	is  => 'ro',
	isa => 'Str',
);





######################################################################
# Events

has OnToolClicked => (
	is  => 'ro',
	isa => 'Str',
);

has OnMenuSelection => (
	is  => 'ro',
	isa => 'Str',
);

has OnToolRClicked => (
	is  => 'ro',
	isa => 'Str',
);

has OnToolEnter => (
	is  => 'ro',
	isa => 'Str',
);

has OnUpdateUI => (
	is  => 'ro',
	isa => 'Str',
);

1;
