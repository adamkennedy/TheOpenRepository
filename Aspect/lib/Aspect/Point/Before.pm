package Aspect::Point::Before;

use strict;
use warnings;
use Aspect::Point ();

our $VERSION = '0.97_04';
our @ISA     = 'Aspect::Point';

use constant type => 'before';

sub original {
	$_[0]->{original};
}

sub proceed {
	@_ > 1 ? $_[0]->{proceed} = $_[1] : $_[0]->{proceed};
}





######################################################################
# Optional XS Acceleration

BEGIN {
	local $@;
	eval <<'END_PERL';
use Class::XSAccessor 1.08 {
	replace => 1,
	getters => {
		'original'   => 'original',
	},
	accessors => {
		'proceed' => 'proceed',
	},
};
END_PERL
}

1;
