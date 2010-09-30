package FBP::StaticText;

use Mouse;

our $VERSION = '0.16';

extends 'FBP::Control';

has label => (
	is  => 'ro',
	isa => 'Str',
);

has permission => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
);

1;
