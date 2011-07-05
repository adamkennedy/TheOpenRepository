package FBP::Sizer;

use Mouse;

our $VERSION = '0.36';

extends 'FBP::Object';
with    'FBP::Children';

# Not part of the Wx model, instead was added by FormBuilder
has name => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
);

no Mouse;
__PACKAGE__->meta->make_immutable;

1;
