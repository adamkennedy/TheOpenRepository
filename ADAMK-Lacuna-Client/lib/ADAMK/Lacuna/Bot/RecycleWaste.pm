package ADAMK::Lacuna::Bot::RecycleWaste;

use 5.008;
use strict;
use warnings;
use List::Util                 ();
use Params::Util               ();
use ADAMK::Lacuna::Bot::Plugin ();

our $VERSION = '0.01';
our @ISA     = 'ADAMK::Lacuna::Bot::Plugin';

sub run {
  my $self   = shift;
  my $client = shift;
  my $empire = $client->empire;

  # Prepare to process the empire
  my $minimum_waste = 100;
  my $recycle_time  = 55 * 60;

  # Iterate over the bodies
  foreach my $planet ( $empire->planets ) {
    my $name = $planet->name;

    # How much waste is on the planet
    my $stored = $planet->waste_stored;
    if ( $stored > $minimum_waste ) {
      $self->trace("$name - Found enough waste to process ($stored)");
    } else {
      $self->trace("$name - Not enough waste to process ($stored)");
      next;
    }

    # If a planet has negative waste flow, don't recycle when there
    # is less than 8 hours to go.
    if ( $planet->waste_hour < 0 and $planet->waste_remaining < (8 * 3600) ) {
      $self->trace("$name - Less than 8 hour supply of waste, won't recycle");
    }

    # Iterate over the waste recycling centers
    foreach my $center ( $planet->waste_recycling_centers ) {
      $self->trace(
        "$name - Checking Waste Recycle Center at " .
        $center->y . ',' . $center->x
      );
      next if     $center->busy;
      next unless $center->level;
      next unless $center->can_recycle;

      # Calculate what to recycle
      my $amount = int List::Util::min(
        $planet->waste_stored,
        $recycle_time / $center->seconds_per_resource,
        $center->max_recycle,
      );
      unless ( Params::Util::_POSINT($amount) ) {
        $self->trace("$name - Failed to establish a recycle quantity");
        next;
      }

      # Determining what to recycle
      my %type = (
        water  => 0,
        ore    => 0,
        energy => 0,
      );
      my @order = grep {
        my $s = "${_}_space";
        $planet->$s() > $amount
      } sort {
        my $l = "${a}_stored";
        my $r = "${b}_stored";
        $planet->$l() <=> $planet->$r()
      } qw{ ore water energy };
      if ( @order ) {
        $type{$order[0]} = $amount;
      } else {
        # Since water is the hardest to accumulate,
        # default to it if there's no better option.
        $self->trace("$name - No preference, using water");
        $type{water} = $amount;
      }

      # Execute the recycle action
      $self->trace(
        "$name - ACTION(Recycling $type{water} water, $type{ore} ore, $type{energy} energy)"
      );
      eval {
        $center->recycle(
          $type{water},
          $type{ore},
          $type{energy},
          0,
        );
      };
      if ( $@ ) {
        $self->trace("$name - ERROR $@");
      }

      # Flush status
      $center->flush;
    }
  }

  return 1;
}

1;
