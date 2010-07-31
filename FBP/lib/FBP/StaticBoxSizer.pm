package FBP::StaticBoxSizer;

use Mouse;

our $VERSION = '0.13';

extends 'FBP::BoxSizer';

has label => (
	is  => 'ro',
	isa => 'Str',
);

1;
