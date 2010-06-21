package FBP::Object;

use Moose;

our $VERSION = '0.01';

has name => (
	is       => 'ro',
	isa      => 'Str',
);

has raw => (
	is       => 'ro',
	isa      => 'Any',
);

1;
