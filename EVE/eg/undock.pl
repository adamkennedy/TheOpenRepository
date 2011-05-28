#!/usr/bin/perl

# Simple script to undock you when in the station

use strict;
use FindBin    ();
use File::Spec ();
use EVE::Game  ();

my $game = EVE::Game->new;

$game->left_click_target('station_undock');
$game->sleep('undock');
$game->left_click_target('ship_autopilot');
