package FBP::Dialog;

use Mouse;

our $VERSION = '0.36';

extends 'FBP::Window';
with    'FBP::Form';
with    'FBP::TopLevelWindow';

has style => (
	is  => 'ro',
	isa => 'Str',
);

no Mouse;
__PACKAGE__->meta->make_immutable;

1;
