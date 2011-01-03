package SDL::Tutorial::3DWorld::Actor::Hedron;

use 5.008;
use strict;
use warnings;
use SDL::Tutorial::3DWorld::Actor ();
use SDL::Tutorial::3DWorld::Model ();

our $VERSION = '0.29';
our @ISA     = 'SDL::Tutorial::3DWorld::Actor';





######################################################################
# Constructor

sub icosahedron {
	my $class = shift;
	my @nodes = (
		[ -90, 0,  ],
		[ -30, 72  ],
		[ -30, 144 ],
		[ -30, 216 ],
		[ -30, 288 ],
		[  30, 36  ],
		[  30, 108 ],
		[  30, 180 ],
		[  30, 252 ],
		[  30, 324 ],
		[  90, 0   ],
	);
	
}

1;
