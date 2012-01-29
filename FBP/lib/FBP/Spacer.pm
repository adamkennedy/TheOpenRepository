package FBP::Spacer;

use Mouse;

our $VERSION = '0.40';

extends 'FBP::Object';

has height => (
	is  => 'ro',
	isa => 'Int',
);

has width => (
	is  => 'ro',
	isa => 'Int',
);

no Mouse;
__PACKAGE__->meta->make_immutable;

1;
