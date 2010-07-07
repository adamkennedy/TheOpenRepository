package FBP::ListBox;

use Mouse;

our $VERSION = '0.07';

extends 'FBP::Window';
with    'FBP::Control';

has style => (
	is  => 'ro',
	isa => 'Str',
);

1;
