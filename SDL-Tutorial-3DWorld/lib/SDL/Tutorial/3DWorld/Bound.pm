package SDL::Tutorial::3DWorld::Bound;

use 5.008;
use strict;
use warnings;
use List::Util ();

our $VERSION = '0.28';

# We can mostly avoid these, but they do help document things
use constant {
	SPHERE_X => 0,
	SPHERE_Y => 1,
	SPHERE_Z => 2,
	SPHERE_R => 3,
	BOX_X1   => 4,
	BOX_Y1   => 5,
	BOX_Z1   => 6,
	BOX_X2   => 7,
	BOX_Y2   => 8,
	BOX_Z2   => 9,
};





######################################################################
# Constructors

sub new {
	my $class = shift;
	return bless [ @_ ], $class;
}

sub box {
	shift->new(
		($_[3] + $_[0]) / 2,
		($_[4] + $_[1]) / 2,
		($_[4] + $_[2]) / 2,
		List::Util::max(
			$_[3] - $_[0],
			$_[4] - $_[1],
			$_[5] - $_[2],
		) / 2,
		@_,
	);
}

sub sphere {
	shift->new(
		@_,
		$_[0] - $_[3],
		$_[1] - $_[3],
		$_[2] - $_[3],
		$_[0] + $_[3],
		$_[1] + $_[3],
		$_[2] + $_[3],
	);
}

1;
