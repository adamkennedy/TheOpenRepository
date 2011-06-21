#!/usr/bin/perl

# Simple script to undock you when in the station

use strict;
use FindBin    ();
use File::Spec ();
use EVE::Game  ();

my $game = EVE::Game->new;
$game->attach;
$game->connect;
$game->mouse_xy;
$game->autopilot_engage();
