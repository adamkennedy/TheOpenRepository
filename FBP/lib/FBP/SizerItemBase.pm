package FBP::SizerItemBase;

use Mouse::Role;

our $VERSION = '0.35';

has border => (
	is  => 'ro',
	isa => 'Int',
);

has flag => (
	is  => 'ro',
	isa => 'Str',
);

no Mouse::Role;

1;
