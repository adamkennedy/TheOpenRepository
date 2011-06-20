package FBP::MenuBar;

use Mouse;

our $VERSION = '0.32';

extends 'FBP::Window';





######################################################################
# Properties

has label => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
	default  => '',
);

has style => (
	is       => 'ro',
	isa      => 'Str',
);

1;
