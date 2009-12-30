package Aspect::Cleanup;

# Convenience class to run an arbitrary function at scope exit.
# Objects may safely be blessed directly into this class if you wish.

use strict;
use warnings;

use overload 'bool'   => sub () { 1     };
use overload '""'     => sub () { ''    };
use overload '+0'     => sub () { 0     };
use overload nomethod => sub () { undef };

sub new {
	bless $_[1], $_[0];
}

sub DESTROY {
	$_[0]->();
}

1;
