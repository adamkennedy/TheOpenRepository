package FBP::Notebook;

our $VERSION = '0.34';

use Mouse;

extends 'FBP::Window';

has bitmapsize => (
	is  => 'ro',
	isa => 'Str',
);

has style => (
	is  => 'ro',
	isa => 'Str',
);

has OnNotebookPageChanged => (
	is  => 'ro',
	isa => 'Str',
);

has OnNotebookPageChanging => (
	is  => 'ro',
	isa => 'Str',
);

no Mouse;
__PACKAGE__->meta->make_immutable;

1;
