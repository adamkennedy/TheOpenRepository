package FBP::CheckBox;

use Mouse;

our $VERSION = '0.39';

extends 'FBP::Control';

has label => (
	is  => 'ro',
	isa => 'Str',
);

has OnCheckBox => (
	is  => 'ro',
	isa => 'Str',
);

no Mouse;
__PACKAGE__->meta->make_immutable;

1;
