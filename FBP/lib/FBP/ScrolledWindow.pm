package FBP::ScrolledWindow;

use Mouse;

our $VERSION = '0.35';

extends 'FBP::Window';

has scroll_rate_x => (
	is  => 'ro',
	isa => 'Int',
);

has scroll_rate_y => (
	is  => 'ro',
	isa => 'Int',
);

no Mouse;
__PACKAGE__->meta->make_immutable;

1;
