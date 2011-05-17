package FBP::StaticBoxSizer;

use Mouse;

our $VERSION = '0.29';

extends 'FBP::BoxSizer';

has label => (
	is  => 'ro',
	isa => 'Str',
);

1;
