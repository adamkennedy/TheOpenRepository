package FBP::Choice;

use Mouse;

our $VERSION = '0.09';

extends 'FBP::Window';
with    'FBP::Control';

has selection => (
	is       => 'ro',
	isa      => 'Int',
	required => 1,
);

1;
