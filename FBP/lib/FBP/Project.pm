package FBP::Project;

use Moose;
use Moose::Util::TypeConstraints;

extends 'FBP::Parent';

has expanded => (
	is  => 'ro',
	isa => 'Bool',
);

1;
