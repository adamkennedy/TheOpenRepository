package FBP::Button;

use Moose;

our $VERSION = '0.02';

extends 'FBP::Parent';

has label => (
	is  => 'ro',
	isa => 'Str',
);

has default => (
	is  => 'ro',
	isa => 'Bool',
);

1;
