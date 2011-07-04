package FBP::Dialog;

use Mouse;

our $VERSION = '0.34';

extends 'FBP::Window';
with    'FBP::Form';
with    'FBP::TopLevelWindow';

has style => (
	is  => 'ro',
	isa => 'Str',
);

1;
