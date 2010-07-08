package FBP::ListBox;

use Mouse;

our $VERSION = '0.08';

extends 'FBP::Window';
with    'FBP::Control';

has style => (
	is  => 'ro',
	isa => 'Str',
);

1;
