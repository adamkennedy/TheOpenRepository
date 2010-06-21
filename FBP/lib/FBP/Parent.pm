package FBP::Parent;

use Moose;

our $VERSION = '0.02';

extends 'FBP::Object';

has children => (
	is  => 'ro',
	isa => "ArrayRef[FBP::Object]",
);

1;
