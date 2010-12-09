package ADAMK::SDL::Debug;

use 5.008;
use strict;
use warnings;
use SDL::Event ':all';

# Event ID reverse map
use vars qw{@EVENT};
BEGIN {
	$EVENT[SDL_ACTIVEEVENT]     = 'SDL_ACTIVEEVENT';
	$EVENT[SDL_KEYDOWN]         = 'SDL_KEYDOWN';
	$EVENT[SDL_KEYUP]           = 'SDL_KEYUP';
	$EVENT[SDL_MOUSEMOTION]     = 'SDL_MOUSEMOTION';
	$EVENT[SDL_MOUSEBUTTONDOWN] = 'SDL_MOUSEBUTTONDOWN';
	$EVENT[SDL_MOUSEBUTTONUP]   = 'SDL_MOUSEBUTTONUP';
	$EVENT[SDL_QUIT]            = 'SDL_QUIT';
	$EVENT[SDL_SYSWMEVENT]      = 'SDL_SYSWMEVENT';
	$EVENT[SDL_VIDEORESIZE]     = 'SDL_VIDEORESIZE';
	$EVENT[SDL_VIDEOEXPOSE]     = 'SDL_VIDEOEXPOSE';
}





######################################################################
# Methods

sub event {
	print "Event: $EVENT[$_[1]]\n";
}

1;
