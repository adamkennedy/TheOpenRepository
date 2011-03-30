package FBP::StaticLine;

use Mouse;

our $VERSION = '0.25';

extends 'FBP::Control';

has style => (
	is  => 'ro',
	isa => 'Str',
);

1;
