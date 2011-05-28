#!/usr/bin/perl

# Tests for market price capture

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 4;
use File::Spec::Functions ':ALL';
use EVE ();

# Data files
my $config = rel2abs(catfile( 'data', 'EVE-Macro.conf' ));
ok( -f $config, "Found test config at $config" );

# Login to the game
my $object = EVE::Game->start(
	# config_file => $config,
	# username    => 'Algorithm2',
	# password    => 'phlegm3{#}',
);
isa_ok( $object, 'EVE::Game' );
ok( $object->login, '->login ok' );

# Get the price of basic minerals
$object->market_search('Mexallon');

ok( $object->stop, '->stop ok' );
