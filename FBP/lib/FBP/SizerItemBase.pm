package FBP::SizerItemBase;

use Mouse::Role;

our $VERSION = '0.34';

has border => (
	is  => 'ro',
	isa => 'Int',
);

has flag => (
	is  => 'ro',
	isa => 'Str',
);

1;
