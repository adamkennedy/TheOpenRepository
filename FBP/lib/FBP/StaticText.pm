package FBP::StaticText;

use Mouse;

our $VERSION = '0.13';

extends 'FBP::Window';
with    'FBP::Control';

has permission => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
);

1;
