#!/usr/bin/perl

# Tests for market price capture

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 5;
use File::Spec::Functions ':ALL';
use EVE ();
use Aspect::Library::Trace qr/^EVE::/;

use constant MARKET_PRODUCTS => qw{
	Tritanium
	Mexallon
	Noxcium
	Zydrine
	1600mm
};

# Data files
my $config = rel2abs(catfile( 'data', 'EVE.conf' ));
ok( -f $config, "Found test config at $config" );

# Login to the game
my $game = EVE::Game->start(
	# config_file => $config,
	# username    => 'Algorithm2',
	# password    => 'phlegm3{#}',
	# debug_pattern => 1,
);
isa_ok( $game, 'EVE::Game' );
ok( $game->login, '->login ok' );
ok( $game->market_start, '->market_start ok' );

# Get the price of several basic materials
$game->market_scan($_) foreach MARKET_PRODUCTS;

ok( $game->stop, '->stop ok' );
