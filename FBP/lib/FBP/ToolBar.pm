package FBP::ToolBar;

use Mouse;

our $VERSION = '0.34';

extends 'FBP::Window';

has bitmapsize => (
	is  => 'ro',
	isa => 'Str',
);

has margins => (
	is  => 'ro',
	isa => 'Str',
);

has packing => (
	is  => 'ro',
	isa => 'Int',
);

has separation => (
	is  => 'ro',
	isa => 'Int',
);

has style => (
	is  => 'ro',
	isa => 'Str',
);

no Mouse;
__PACKAGE__->meta->make_immutable;

1;
