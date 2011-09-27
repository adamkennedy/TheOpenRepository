package FBP::MenuSeparator;

use Mouse;

our $VERSION = '0.38';

extends 'FBP::Object';

has name => (
	is  => 'ro',
	isa => 'Str',
);

no Mouse;
__PACKAGE__->meta->make_immutable;

1;
