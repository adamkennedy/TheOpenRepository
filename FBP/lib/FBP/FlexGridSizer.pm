package FBP::FlexGridSizer;

use Mouse;

our $VERSION = '0.24';

extends 'FBP::GridSizer';

has flexible_direction => (
	is  => 'ro',
	isa => 'Str',
);

has non_flexible_grow_mode => (
	is  => 'ro',
	isa => 'Str',
);

has growablecols => (
	is      => 'ro',
	isa     => 'Str',
	default => '',
);

has growablerows => (
	is      => 'ro',
	isa     => 'Str',
	default => '',
);

1;
