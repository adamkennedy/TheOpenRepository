package FBP::FlexGridSizer;

use Mouse;

our $VERSION = '0.34';

extends 'FBP::Sizer';
with    'FBP::FlexGridSizerBase';

has rows => (
	is  => 'ro',
	isa => 'Int',
);

has cols => (
	is  => 'ro',
	isa => 'Int',
);

1;
