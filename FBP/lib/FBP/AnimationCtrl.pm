package FBP::AnimationCtrl;

use Mouse;

our $VERSION = '0.34';

extends 'FBP::Control';

has style => (
	is  => 'ro',
	isa => 'Str',
);

has animation => (
	is  => 'ro',
	isa => 'Str',
);

has inactive_bitmap => (
	is  => 'ro',
	isa => 'Str',
);

has play => (
	is  => 'ro',
	isa => 'Bool',
);

1;
