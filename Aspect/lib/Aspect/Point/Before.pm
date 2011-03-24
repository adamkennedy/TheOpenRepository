package Aspect::Point::Before;

use strict;
use warnings;
use Aspect::Point ();

our $VERSION = '0.97';
our @ISA     = 'Aspect::Point';

use constant type => 'before';

sub original {
	$_[0]->{original};
}

sub proceed {
	@_ > 1 ? $_[0]->{proceed} = $_[1] : $_[0]->{proceed};
}

1;
