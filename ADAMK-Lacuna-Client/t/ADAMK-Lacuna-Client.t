#!/usr/bin/perl

use 5.008;
use strict;
use warnings;
use Test::More;
use ADAMK::Lacuna::Client;

if ( -f 'lacuna.yml' ) {
  plan( tests => 20 );
} else {
  plan( skip_all => 'No lacuna.yml file' );
}





######################################################################
# Main tests

# Connect to the game
my $client = new_ok( 'ADAMK::Lacuna::Client' );

# Fetch our empire
my $empire = $client->empire;
isa_ok($empire, 'ADAMK::Lacuna::Client::Empire');

# Fetch our home
my $home = $empire->home_planet;
isa_ok( $home, 'ADAMK::Lacuna::Client::Body' );

# Fetch a status element for our home
ok( $home->building_count > 20, '->building_count' );

# Fetch our home planet's buildings
my @building = $home->buildings;
ok( scalar(@building), '->buildings' );
isa_ok( $building[0], 'ADAMK::Lacuna::Client::Buildings' );

# Fetch special single-instance buildings
my %SINGLE = (
  capitol                   => 'Capitol',
  development_ministry      => 'DevelopmentMinistry',
  embassy                   => 'Embassy',
  espionage_ministry        => 'EspionageMinistry',
  intelligence_ministry     => 'IntelligenceMinistry',
  mining_ministry           => 'MiningMinistry',
  network_19_affiliate      => 'Network19Affiliate',
  observatory               => 'Observatory',
  security_ministry         => 'SecurityMinistry',
  trade_ministry            => 'TradeMinistry',
  pilot_training_facility   => 'PilotTrainingFacility',
  planetary_command_center  => 'PlanetaryCommandCenter',
  propulsion_system_factory => 'PropulsionSystemFactory',
  university                => 'University',
);
foreach ( sort keys %SINGLE ) {
  isa_ok( $home->$_(), "ADAMK::Lacuna::Client::Buildings::$SINGLE{$_}" );
}
