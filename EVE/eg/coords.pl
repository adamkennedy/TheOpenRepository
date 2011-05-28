#!/usr/bin/perl

use strict;
use FindBin    ();
use File::Spec ();
use EVE::Game  ();





#####################################################################
# Main Script

my $game = EVE::Game->start;

while ( 1 ) {
	my $coord = $game->mouse_xy;
	print "Mouse at: $coord->[0],$coord->[1]\n";
	sleep(1);
}

$game->stop;
