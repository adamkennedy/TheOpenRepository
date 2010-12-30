package SDL::Tutorial::3DWorld::HeightMap;

use 5.008;
use strict;
use warnings;
use POSIX ();

our $VERSION = '0.26';

use constant D2R => CORE::atan2(1,1) / 45;

# Random gradient cache
our %CACHE = ();

# Perlin Noise function. Based on the following algorithm description.
# http://webstaff.itn.liu.se/~stegu/TNM022-2005/perlinnoiselinks/perlin-noise-math-faq.html#algorithm
# noise2d(x,y) = z
sub noise2d ($$) {
	my $x = shift;
	my $y = shift;

	# Find the grid around the point
	my $x0 = POSIX::floor($x);
	my $y0 = POSIX::floor($y);
	my $x1 = POSIX::ceil($x);
	my $y1 = POSIX::ceil($y);

	# Find the gradients for each grid point
	my $g00 = ($CACHE{$x0,$y0} or $CACHE{$x0,$y0} = rand2d());
	my $g10 = ($CACHE{$x1,$y0} or $CACHE{$x1,$y0} = rand2d());
	my $g01 = ($CACHE{$x0,$y1} or $CACHE{$x0,$y1} = rand2d());
	my $g11 = ($CACHE{$x1,$y1} or $CACHE{$x1,$y1} = rand2d());
	
	
}

sub rand2d() {
	my $angle = rand(360) * D2R;
	return [ sin($angle), cos($angle) ];
}

1;
