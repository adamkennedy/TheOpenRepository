#!/usr/bin/perl

use 5.008;
use strict;
use warnings;
use Test::More;
use ADAMK::Lacuna::Client;
use ADAMK::Lacuna::Bot;

if ( -f 'lacuna.yml' ) {
  plan( tests => 3 );
} else {
  plan( skip_all => 'No lacuna.yml file' );
}





######################################################################
# Main tests

# Create the bot
my $bot = new_ok( 'ADAMK::Lacuna::Bot', [
  MoveWaste => 1,
] );

# Connect to the game
my $client = new_ok( 'ADAMK::Lacuna::Client' );

# Execute the bot
ok( $bot->run($client), '->run ok' );
