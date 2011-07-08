#!/usr/bin/perl

# Things to do in Jita

use 5.008;
use strict;
use warnings;
use EVE::DB   ();
use EVE::Game ();
use EVE::Plan ();
use EVE::Shell;

unless ( @ARGV ) {
	die "Did not provide any market segments to scan";
}

# Bootstrap and initialise
my $game = EVE::Game->new;
$game->attach;
$game->connect;
$game->mouse_xy;
#$game->reset_windows;
$game->market_pricing(@ARGV);
$game->stop;
