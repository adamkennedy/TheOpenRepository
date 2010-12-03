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
    Repair        => 1,
    Archaeology   => 1,
    MoveWaste     => 1,
    MoveResources => 1,
    RecycleWaste  => 1,
    Alerts        => 1,
    Summary       => 1,
  );
  print "Running bot...\n";
  $bot->run( $client );

  print "Waiting for an hour...\n";
  sleep 3600;
}
