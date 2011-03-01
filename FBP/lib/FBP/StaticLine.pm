package FBP::StaticLine;

use Mouse;

our $VERSION = '0.21';

extends 'FBP::Control';

has style => (
	is  => 'ro',
	isa => 'Str',
);

1;
