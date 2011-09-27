package FBP::GridBagSizer;

use Mouse;

our $VERSION = '0.38';

extends 'FBP::Sizer';
with    'FBP::FlexGridSizerBase';

has empty_cell_size => (
	is       => 'ro',
	isa      => 'Str',
);

no Mouse;
__PACKAGE__->meta->make_immutable;

1;
