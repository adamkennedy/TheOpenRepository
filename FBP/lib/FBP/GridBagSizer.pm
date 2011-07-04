package FBP::GridBagSizer;

use Mouse;

our $VERSION = '0.33';

extends 'FBP::Sizer';
with    'FBP::FlexGridSizerBase';

has empty_cell_size => (
	is       => 'ro',
	isa      => 'Str',
);

1;
