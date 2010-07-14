package FBP::StaticLine;

use Mouse;

our $VERSION = '0.12';

extends 'FBP::Window';
with    'FBP::Control';

has style => (
	is  => 'ro',
	isa => 'Str',
);

1;
