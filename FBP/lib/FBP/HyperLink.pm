package FBP::HyperLink;

use Mouse;

our $VERSION = '0.31';

extends 'FBP::Control';





######################################################################
# Properties

has label => (
	is       => 'ro',
	isa      => 'Str',
);

has url => (
	is       => 'ro',
	isa      => 'Str',
);

has hover_color => (
	is       => 'ro',
	isa      => 'Str',
);

has normal_color => (
	is       => 'ro',
	isa      => 'Str',
);

has visited_color => (
	is       => 'ro',
	isa      => 'Str',
);

has style => (
	is       => 'ro',
	isa      => 'Str',
);





######################################################################
# Events

has OnHyperlink => (
	is  => 'ro',
	isa => 'Str',
);

1;
