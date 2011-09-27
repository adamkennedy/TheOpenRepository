package FBP::StaticBoxSizer;

use Mouse;

our $VERSION = '0.38';

extends 'FBP::BoxSizer';

has label => (
	is  => 'ro',
	isa => 'Str',
);

no Mouse;
__PACKAGE__->meta->make_immutable;

1;
