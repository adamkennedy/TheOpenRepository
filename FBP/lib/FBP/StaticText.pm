package FBP::StaticText;

use Moose;

our $VERSION = '0.02';

extends 'FBP::Parent';

has label => (
	is  => 'ro',
	isa => 'Str',
);

1;
