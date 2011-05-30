#!/usr/bin/perl

use strict;
use FindBin    ();
use File::Spec ();
use EVE::Game  ();





#####################################################################
# Main Script

my $game = EVE::Game->new;
$game->attach;
$game->connect;
$game->set_destination($ARGV[0]);
$game->sleep(10);
