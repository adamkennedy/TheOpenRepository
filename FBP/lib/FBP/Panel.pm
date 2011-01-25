package FBP::Panel;

use Mouse;

our $VERSION = '0.17';

extends 'FBP::Window';

has permission => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
);

1;
