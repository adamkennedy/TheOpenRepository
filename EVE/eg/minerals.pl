#!/usr/bin/perl

use 5.008;
use strict;
use warnings;
use EVE::DB   ();
use EVE::Game ();
use EVE::Plan ();
use EVE::Shell;
# use Aspect::Library::Trace qr/EVE::Game::(?:market_group|market_type|market_search)/;

# Reset all records
EVE::Trade::Market->truncate;
EVE::Trade::Price->truncate;

# Bootstrap and initialise
my $game = EVE::Game->new;
$game->attach;
$game->connect;
$game->mouse_xy;
$game->reset_windows;
$game->market_start;

# Capture all the normal minerals
my @result = EVE::Plan->manufacturing($game);

$game->stop;

1;
