package FBP::Object;

use 5.008005;
use Moose;

has name => (
	is       => 'ro',
	isa      => 'Str',
);

has property => (
	is       => 'rw',
	isa      => 'HashRef[Str]',
	required => 1,
	default  => sub { +{ } },
);

has event => (
	is       => 'rw',
	isa      => 'HashRef[Str]',
	required => 1,
	default  => sub { +{ } },
);

sub add_property {
	$_[0]->property->{$_[1]} = $_[2];
}

sub add_event {
	$_[0]->event->{$_[1]} = $_[2];
}

1;
