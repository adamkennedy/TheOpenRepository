package FBP::Sizer;

use Mouse;

our $VERSION = '0.05';

extends 'FBP::Object';
with    'FBP::Children';

# Not part of the Wx model, instead was added by FormBuilder
has name => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
);

1;
