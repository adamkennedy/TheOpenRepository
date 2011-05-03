package FBP::StaticLine;

use Mouse;

our $VERSION = '0.26';

extends 'FBP::Control';

has style => (
	is  => 'ro',
	isa => 'Str',
);

1;
