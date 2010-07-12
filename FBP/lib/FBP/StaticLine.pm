package FBP::StaticLine;

use Mouse;

our $VERSION = '0.11';

extends 'FBP::Window';
with    'FBP::Control';

has style => (
	is  => 'ro',
	isa => 'Str',
);

1;
