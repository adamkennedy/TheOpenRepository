package FBP::Object;

use Moose;

our $VERSION = '0.01';

has name => (
	is       => 'ro',
	isa      => 'Str',
);

1;
