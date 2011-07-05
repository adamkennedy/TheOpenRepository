package FBP::Form;

use Mouse::Role;

our $VERSION = '0.35';

has OnInitDialog => (
	is  => 'ro',
	isa => 'Str',
);

no Mouse::Role;

1;
