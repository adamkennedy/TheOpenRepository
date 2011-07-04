package FBP::Notebook;

our $VERSION = '0.34';

use Mouse;

extends 'FBP::Window';

has bitmapsize => (
	is  => 'ro',
	isa => 'Str',
);

has style => (
	is  => 'ro',
	isa => 'Str',
);

1;
