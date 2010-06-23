package FBP::Button;

use Moose;

our $VERSION = '0.04';

extends 'FBP::Window';
with    'FBP::Control';

has OnButtonClick => (
	is  => 'ro',
	isa => 'Str',
);

1;
