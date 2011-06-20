#!/usr/bin/perl

use 5.008;
use strict;
use warnings;
use EVE::Shell;
use Aspect::Library::Trace qr/EVE::Game::(?:market_group|market_type|market_search)/;

# Bootstrap and initialise
my $game = EVE::Game->new;
$game->attach;
$game->connect;
$game->mouse_xy;
$game->reset_windows;
$game->market_start;

# Capture all the normal minerals
foreach my $gid ( EVE::Game::TRADE_GROUP_MINERALS ) {
	$game->market_group($gid);
}

1;
