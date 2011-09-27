package FBP::StaticText;

use Mouse;

our $VERSION = '0.38';

extends 'FBP::Control';

has label => (
	is  => 'ro',
	isa => 'Str',
);

has wrap => (
	is       => 'ro',
	isa      => 'Str',
	default  => '-1',
);

no Mouse;
__PACKAGE__->meta->make_immutable;

1;
