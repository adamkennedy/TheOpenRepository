package FBP::Form;

use Mouse::Role;

our $VERSION = '0.34';

has OnInitDialog => (
	is  => 'ro',
	isa => 'Str',
);

no Mouse::Role;

1;
