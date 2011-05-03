package FBP::BoxSizer;

use Mouse;

our $VERSION = '0.26';

extends 'FBP::Sizer';

has orient => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
);

1;
