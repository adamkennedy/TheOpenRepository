package XRC::BoxSizer;

use Moose;
use Moose::Util::TypeConstraints;

enum 'Orient' => qw{
	wxVERTICAL
	wxHORIZONTAL
};

extends 'XRC::Object';

has orient => (
	is  => 'rw',
	isa => 'Orient',
);

1;
