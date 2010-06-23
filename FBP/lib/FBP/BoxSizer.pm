package FBP::BoxSizer;

use Moose;

our $VERSION = '0.04';

extends 'FBP::Sizer';

has orient => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
);

1;
