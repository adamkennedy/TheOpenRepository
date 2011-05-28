#!/usr/bin/perl

# Simple script to undock you when in the station

use strict;
use FindBin    ();
use File::Spec ();
use EVE::Game  ();

my $game = EVE::Game->new;
$game->attach;
$game->connect;

# Constantly look for and mouseover the destination gate
while ( 1 ) {
	my $match1 = $game->screenshot_has('overview-destination');
	unless ( $match1 ) {
		$game->sleep(0.5);
		next;
	}

	# Select the gate
	$game->left_click($match1);
	$game->sleep(0.5);

	# After selecting the gate, the pattern should no longer match
	my $match2 = $game->screenshot_has('overview-destination');
	if ( $match2 ) {
		# We probably clicked on the wrong thing, reset
		next;
	}

	# We probably clicked on the correct gate.
	# Use the standard hotkey to warp to the gate.
	$game->send_keys('sssssssss');
	$game->sleep(5);

	# Hit jump periodically until we can see a gate again
	while ( ! $game->screenshot_has('overview-destination') ) {
		$game->send_keys('d');
	}
}
