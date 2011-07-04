package FBP::FlexGridSizer;

use Mouse;

our $VERSION = '0.33';

extends 'FBP::Sizer';
with    'FBP::FlexSizer';

has rows => (
	is  => 'ro',
	isa => 'Int',
);

has cols => (
	is  => 'ro',
	isa => 'Int',
);

1;
