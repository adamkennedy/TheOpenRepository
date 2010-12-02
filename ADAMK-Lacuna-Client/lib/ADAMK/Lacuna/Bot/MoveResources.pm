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
  my %from = map { $_ => {} } TYPES;
  my %to   = map { $_ => {} } TYPES;
  foreach my $planet_id ( $empire->planet_ids ) {
    my $planet = $empire->planet($planet_id);
    my $name   = $planet->name;
    $self->trace("Checking planet $name for overflow or excess space");

    # Can we accept surplus resources?
    foreach my $type ( TYPES ) {
        # Get resource information
        my $space_method = "${type}_space";
        my $hour_method  = "${type}_hour";
        my $space        = $planet->$space_method();
        my $hour         = $planet->$hour_method();

        # How much can we accept from elsewhere
        if ( $hour > 0 ) {
            $space = $space - (4 * $hour);
            $space = 0 if $space < 0;
        } else {
            # Just go with the space there now
        }
        if ( $space > 0 ) {
            my $hours = int($space / $hour) + 1;
            $self->trace("$name - Can accept $space $type, $hours hour(s) supply");
            $to{$type}->{$planet_id} = [ $space, $hours ];
        }

        # How much can we send to elsewhere
        if ( $hour > 0 ) {
            my $remaining_method = "${type}_remaining";
            my $remaining        = $planet->$remaining_method();
            if ( $remaining < 4 ) {
                # Always keep an emergency buffer
                my $stored_method = "${type}_stored";
                my $stored        = $planet->$stored_method() - 10000;
                $stored = 0 if $stored < 0;

                # Check shipping as late as possible to reduce API calls
                if ( $stored and $planet->cargo_ships ) {
                    $remaining = int($remaining);
                    $self->trace("$name - Can supply $stored $type, $remaining hour(s) from storage limit");
                    $from{$type}->{$planet_id} = [ $stored, $remaining ];
                }
            }
        }
    }
  }

  # Find the best shipping combinations
  1;

  # If transport ships are already inbound, skip in case a bug has
  # caused overshipping.
  ### TO BE COMPLETED

  return 1;
}

sub trace {
  print scalar(localtime time) . " - MoveResources - " . $_[1] . "\n";
}

1;
