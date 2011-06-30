package FBP::Form;

use Mouse::Role;

our $VERSION = '0.33';

has OnInitDialog => (
	is  => 'ro',
	isa => 'Str',
);

1;
