package ADAMK::Lacuna::Bot::Alerts;

use 5.008;
use strict;
use warnings;
use ADAMK::Lacuna::Bot::Plugin ();

our $VERSION = '0.01';
our @ISA     = 'ADAMK::Lacuna::Bot::Plugin';

sub run {
  my $self   = shift;
  my $client = shift;
  my $empire = $client->empire;

  # Preparatory work
  $self->trace("Predetermining Archaeology Planet");
  my $arch_hq = $empire->archaeology_planet->body_id;

  # Iterate over the bodies
  foreach my $planet ( $empire->planets ) {
    my $name    = $planet->name;
    my $body_id = $planet->body_id;

    # Check for the planet being idle
    unless ( $planet->pending_builds ) {
      $self->trace("$name - ALERT - Nothing building");
    }

    # Check for planetary storage levels being full
    unless ( $planet->energy_space ) {
      $self->trace("$name - ALERT - Energy storage full");
    }
    unless ( $planet->food_space ) {
      $self->trace("$name - ALERT - Food storage full");
    }
    unless ( $planet->ore_space ) {
      $self->trace("$name - ALERT - Ore storage full");
    }
    unless ( $planet->water_space ) {
      $self->trace("$name - ALERT - Water storage full");
    }
    unless ( $planet->waste_space ) {
      $self->trace("$name - DANGER - Waste storage full");
    }

    # Check for uncentralised glyphs
    my $archaeology = $planet->archaeology_ministry;
    if ( $archaeology ) {
      unless ( $arch_hq == $body_id ) {
        my $glyphs = $archaeology->glyphs;
        if ( $glyphs ) {
          $self->trace("$name - WARNING - $glyphs x Uncentralised Glyph");
        }
      }
    }

    # Check for a mining ministry being underserviced
    my $mining = $planet->mining_ministry;
    if ( $mining ) {
      # Check for underused mining ministry
      my $available  = $mining->platforms_available;
      my $travelling = $planet->ships(
        type => 'Mining Platform Ship',
        task => 'Travelling',
      );
      my $unused = $available - $travelling;
      if ( $unused < 0 ) {
        $self->trace("$name - ERROR - Number of unused asteroid mining slots is less than zero ($unused)");
      } elsif ( $unused > 0 ) {
        # NOTE: This does not take into account mining platforms that
        # are already in transit to an asteroid.
        $self->trace("$name - ALERT - Mining Ministry has unused platform slots");
      }

      # Check for underserved mining ministry
      my $capacity = $mining->shipping_capacity;
      if ( $capacity > 100 ) {
        $self->trace("$name - ALERT - Mining Ministry shipping is underserved ($capacity)");
      }
    }

    # Check for an underused observatory
    my $observatory = $planet->observatory;
    if ( $observatory ) {
      my $available  = $observatory->probes_available;
      my $travelling = $planet->ships(
        type => 'Probe',
        task => 'Travelling',
      );
      my $unused = $available - $travelling;
      if ( $unused > 0 ) {
        $self->trace("$name - WARNING - Observatory has unused probe slots ($unused)");
      }
    }

    # Check for full shipyards
    my $spaceport = $planet->space_port;
    if ( $spaceport and not $spaceport->docks_available ) {
      $self->trace("$name - ALERT - Space Port is full to capacity");
    }

    # Check for substandard defenses
    my $fighters = scalar $planet->ships(
        type => 'Fighter',
        task => 'Docked',
    );
    if ( $fighters < 2 ) {
      $self->trace("$name - DANGER - Substandard Fighter defense level ($fighters)");
    }

    # Report available weapons
    foreach my $type ( qw{ Excavator Probe Scanner Detonator Snark } ) {
      my $ships = scalar $planet->ships(
        type => $type,
        task => 'Docked',
      ) or next;
      $self->trace("$name - NOTICE - $ships $type(s) ready to fire");
    }
  }

  return 1;
}

1;
