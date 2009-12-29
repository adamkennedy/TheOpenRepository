package XRC::Object;

use 5.008005;
use Moose;

has name => (
	is       => 'ro',
	isa      => 'Str',
);

1;
