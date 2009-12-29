package XRC::Size;

use 5.008005;
use Moose;

our $VERSION = '0.01';

has width => (
	is      => 'ro',
	isa     => 'Int',
	default => -1,
);

has height => (
	is      => 'ro',
	isa     => 'Int',
	default => -1,
);

1;
