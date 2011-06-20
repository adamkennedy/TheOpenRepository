package FBP::StatusBar;

use Mouse;

our $VERSION = '0.31';

extends 'FBP::Window';





######################################################################
# Properties

has fields => (
	is       => 'ro',
	isa      => 'Int',
);

has style => (
	is       => 'ro',
	isa      => 'Str',
);

1;
