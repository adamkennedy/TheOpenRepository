package FBP::NotebookPage;

use Mouse;

our $VERSION = '0.34';

extends 'FBP::Object';
with    'FBP::Children';

has label => (
	is  => 'ro',
	isa => 'Str',
);

has bitmap => (
	is  => 'ro',
	isa => 'Str',
);

has select => (
	is  => 'ro',
	isa => 'Bool',
);

1;
