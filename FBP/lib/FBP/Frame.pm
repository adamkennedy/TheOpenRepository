package FBP::Frame;

use Mouse;

our $VERSION = '0.30';

extends 'FBP::Window';
with    'FBP::Form';
with    'FBP::TopLevelWindow';

has style => (
	is  => 'ro',
	isa => 'Str',
);

1;
