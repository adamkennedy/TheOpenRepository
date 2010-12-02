package ADAMK::Lacuna::Bot::MoveResources;

use 5.008;
use strict;
use warnings;
use List::Util                 ();
use Params::Util               ();
use ADAMK::Lacuna::Bot::Plugin ();

our $VERSION = '0.01';
our @ISA     = 'ADAMK::Lacuna::Bot::Plugin';

use constant HOUR  => 3600;
use constant TYPES => qw{ food ore water energy };

sub run {
  my $self   = shift;
  my $client = shift;
  my $empire = $client->empire;

  # Precalculate which planet/resource combinations are in excess
  # and which planet/resource combinations have excess space.
  my %from = map { $_ => 1 } TYPES;
  my %to   = map { $_ => 1 } TYPES;
  foreach my $planet_id ( $empire->planet_ids ) {
    my $planet = $empire->planet($planet_id);
    my $name   = $planet->name;
    $self->trace("Checking planet $name for overflow or excess space");

    # Can we accept surplus resources?
    foreach my $type ( TYPES ) {
      
    }

    # If transport ships are already inbound, skip in case a bug has
    # caused overshipping.
    ### TO BE COMPLETED

    # Do we need to pull waste from elsewhere to prevent
    # waste exhaustion and building damage?
    if ( $planet->waste_hour < 0 and $planet->waste_remaining < EIGHT_HOURS ) {
      # Where can we pull waste from
      my $source = $self->best_waste_source( $planet );
      if ( $source ) {
        # Waste usually moves in big volumes, select the biggest ship
        my $ship = (
          sort {
            $b->{hold_size} <=> $a->{hold_size}
          } $source->cargo_ships
        )[0];

        # Determine the amount of waste to transport
        my $quantity = List::Util::min(
          $planet->waste_space,
          $ship->{hold_size},
        );

        # Execute the transport push
        $self->trace("$name - Pulling $quantity waste from " . $source->name . " to resolve shortage");
        $source->push_items(
          $planet,
          [
            {
              type     => 'waste',
              quantity => $quantity,
            }
          ],
          {
            ship_id => $ship->{id},
          },
        );

        1;
      }
    }

  }

  return 1;
}

# Given a destination planet, where is the best place to source it from.
# This implementation is sub-optimal, but is a decent initial attempt.
sub best_waste_source {
  my $self   = shift;
  my $planet = shift;

  # Start with the list of planets that could actually ship us something
  my @source = grep {
    scalar $_->cargo_ships
  } grep {
    $_->trade_ministry
  } $planet->other_planets;

  # Pull from the biggest absolute pool of waste, someone is bound to have a ton of it.
  @source = sort {
    $b->waste_stored <=> $a->waste_stored
  } @source;

  return $source[0];
}

sub trace {
  print scalar(localtime time) . " - MoveWaste - " . $_[1] . "\n";
}

1;
