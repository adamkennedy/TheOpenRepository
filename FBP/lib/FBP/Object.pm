package FBP::Object;

use Moose;

our $VERSION = '0.02';

has name => (
	is       => 'ro',
	isa      => 'Str',
);

has raw => (
	is       => 'ro',
	isa      => 'Any',
);

1;
