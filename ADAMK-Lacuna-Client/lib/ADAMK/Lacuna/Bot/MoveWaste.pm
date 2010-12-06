package ADAMK::Lacuna::Bot::MoveWaste;

use 5.008;
use strict;
use warnings;
use List::Util                 ();
use Params::Util               ();
use ADAMK::Lacuna::Bot::Plugin ();

our $VERSION = '0.01';
our @ISA     = 'ADAMK::Lacuna::Bot::Plugin';

use constant EIGHT_HOURS => 3600 * 8;

sub run {
  my $self   = shift;
  my $client = shift;
  my $empire = $client->empire;

  # Iterate over the bodies
  foreach my $planet ( $empire->planets ) {
    # If transport ships are already inbound, skip in case a bug has
    # caused overshipping.
    ### TO BE COMPLETED

    # Do we need to pull waste from elsewhere to prevent
    # waste exhaustion and building damage? In addition, try to keep our
    # waste collection at least a quarter full.
    if ( $planet->waste_hour < 0 and $planet->waste_remaining < EIGHT_HOURS ) {
      # Where can we pull waste from
      my $source = $self->best_waste_source($planet);
      if ( $source ) {
        # Find a ship to use
        my $ship = $source->cargo_ship;

        # Determine the amount of waste to transport
        my $quantity = List::Util::min(
          $planet->waste_space,
          $ship->hold_size,
        );

        # Execute the transport push
        my $name = $planet->name;
        $self->trace("$name - Pulling $quantity waste from " . $source->name . " to resolve shortage");
        $ship->push_items(
          $planet,
          {
            type     => 'waste',
            quantity => $quantity,
          }
        );
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

1;
