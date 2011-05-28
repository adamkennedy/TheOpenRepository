#!/usr/bin/perl

# Simple script to undock you when in the station

use strict;
use FindBin    ();
use File::Spec ();
use EVE::Game  ();

my $game = EVE::Game->new;
$game->attach;
$game->connect;

my $pattern = shift(@ARGV);

# Constantly look for and mouseover the destination gate
while ( 1 ) {
	my $match = $game->screenshot_has($pattern);
	if ( $match ) {
		my $from = $game->mouse_xy;
		$game->mouse_flicker($match);
		$game->mouse_to( $from );
	}
	$game->sleep(0.5);
}
