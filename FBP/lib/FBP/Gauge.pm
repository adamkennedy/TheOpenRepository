package FBP::Gauge;

use Mouse;

our $VERSION = '0.33';

extends 'FBP::Control';





######################################################################
# Properties

has value => (
	is       => 'ro',
	isa      => 'Int',
);

has range => (
	is       => 'ro',
	isa      => 'Int',
);

has style => (
	is       => 'ro',
	isa      => 'Str',
);

1;
