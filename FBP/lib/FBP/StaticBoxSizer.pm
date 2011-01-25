package FBP::StaticBoxSizer;

use Mouse;

our $VERSION = '0.17';

extends 'FBP::BoxSizer';

has label => (
	is  => 'ro',
	isa => 'Str',
);

1;
