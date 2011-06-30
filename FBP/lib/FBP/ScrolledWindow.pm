package FBP::ScrolledWindow;

use Mouse;

our $VERSION = '0.33';

extends 'FBP::Window';

has scroll_rate_x => (
	is  => 'ro',
	isa => 'Int',
);

has scroll_rate_y => (
	is  => 'ro',
	isa => 'Int',
);

1;
