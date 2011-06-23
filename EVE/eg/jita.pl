#!/usr/bin/perl

# Things to do in Jita

use 5.008;
use strict;
use warnings;
use EVE::DB   ();
use EVE::Game ();
use EVE::Plan ();
use EVE::Shell;

# Bootstrap and initialise
my $game = EVE::Game->new;
$game->attach;
$game->connect;
$game->mouse_xy;
$game->reset_windows;

# Capture pricing for all my current orders
EVE::Plan->scan_inelastic($game);
EVE::Plan->scan_orders($game);
EVE::Plan->scan_assets($game);
EVE::Plan->scan_manufacturing($game);
EVE::Plan->scan_reactions($game);

$game->stop;

1;
