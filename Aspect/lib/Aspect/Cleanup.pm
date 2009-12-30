package Aspect::Cleanup;

# Convenience class to run an arbitrary function at scope exit.
# Objects may safely be blessed directly into this class if you wish.

use strict;
use warnings;

use overload
	q{""}   => sub { undef },
	q{0+}   => sub { undef },
	q{bool} => sub { undef };

sub new { bless $_[1], $_[0] }

sub DESTROY { $_[0]->() }

1;
