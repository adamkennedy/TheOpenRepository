package FBP::Dialog;

use Moose;

our $VERSION = '0.03';

extends 'FBP::Window';

has pos => (
	is  => 'ro',
	isa => 'Str',
);

has size => (
	is  => 'ro',
	isa => 'Str',
);

has style => (
	is  => 'ro',
	isa => 'Str',
);

1;
