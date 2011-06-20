package FBP::MenuItem;

use Mouse;

our $VERSION = '0.32';

extends 'FBP::Object';





######################################################################
# Properties

has id => (
	is  => 'ro',
	isa => 'Str',
);

has name => (
	is  => 'ro',
	isa => 'Str',
);

has label => (
	is  => 'ro',
	isa => 'Str',
);

has shortcut => (
	is  => 'ro',
	isa => 'Str',
);

has help => (
	is  => 'ro',
	isa => 'Str',
);

has bitmap => (
	is  => 'ro',
	isa => 'Str',
);

has unchecked_bitmap => (
	is  => 'ro',
	isa => 'Str',
);

has checked => (
	is  => 'ro',
	isa => 'Bool',
);

has enabled => (
	is  => 'ro',
	isa => 'Bool',
);

has kind => (
	is  => 'ro',
	isa => 'Str',
);





######################################################################
# Events

has OnMenuSelection => (
	is  => 'ro',
	isa => 'Str',
);

has OnUpdateUI => (
	is  => 'ro',
	isa => 'Str',
);

1;
