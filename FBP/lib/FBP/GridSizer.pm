package FBP::GridSizer;

use Mouse;

our $VERSION = '0.12';

extends 'FBP::Sizer';

has rows => (
	is       => 'ro',
	isa      => 'Int',
	required => 1,
);

has cols => (
	is       => 'ro',
	isa      => 'Int',
	required => 1,
);

has vgap => (
	is       => 'ro',
	isa      => 'Int',
	required => 1,
);

has hgap => (
	is       => 'ro',
	isa      => 'Int',
	required => 1,
);

1;
