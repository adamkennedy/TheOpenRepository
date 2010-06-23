package FBP::Control;

use Moose::Role;

our $VERSION = '0.04';

has default => (
	is  => 'ro',
	isa => 'Bool',
);

1;
