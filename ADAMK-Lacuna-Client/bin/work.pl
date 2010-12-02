#!/usr/bin/perl

use 5.008;
use strict;
use warnings;
use Test::More;
use ADAMK::Lacuna::Client;
use ADAMK::Lacuna::Bot;

unless ( -f 'lacuna.yml' ) {
  exit(0);
}





######################################################################
# Create and run the bot

while ( 1 ) {
  my $client = ADAMK::Lacuna::Client->new;
  my $bot    = ADAMK::Lacuna::Bot->new(
    # Plugins that take independant action
    Archaeology => {
      prefer => [ 'Rutile', 'Kerogen' ],
    },
    RecycleWaste => 1,
    MoveWaste    => 1,

    # Unresolved issues needing human attention
    Alerts  => 1,
    Summary => 1,
  );
  print "Running bot...\n";
  $bot->run( $client );

  print "Waiting for an hour...\n";
  sleep 3600;
}
