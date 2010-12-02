package ADAMK::Lacuna::Bot::Summary;

use 5.008;
use strict;
use warnings;
use ADAMK::Lacuna::Bot::Plugin ();

our $VERSION = '0.01';
our @ISA     = 'ADAMK::Lacuna::Bot::Plugin';

my @ADDABLE = qw{
  energy_hour
  energy_stored
  energy_capacity
  food_hour
  food_stored
  food_capacity
  ore_hour
  ore_stored
  ore_capacity
  water_hour
  water_stored
  water_capacity
  waste_hour
  waste_stored
  waste_capacity
};

sub run {
  my $self   = shift;
  my $client = shift;
  my $empire = $client->empire;

  # Iterate over the bodies
  my %total = ();
  foreach my $planet_id ( $empire->planet_ids ) {
    my $planet = $empire->planet($planet_id);

    # Total all the common resources
    foreach my $method ( @ADDABLE ) {
      $total{$method} = 0 unless defined $total{$method};
      $total{$method} += $planet->$method();
    }
  }

  # Synthesize the derived values and summarise
  foreach my $type ( qw{ food ore water energy waste } ) {
    my $name      = ucfirst $type;
    my $hour      = $total{"${type}_hour"};
    my $stored    = $total{"${type}_stored"};
    my $capacity  = $total{"${type}_capacity"};
    my $space     = $capacity - $stored;
    my $time      = int( $capacity / $hour );
    my $remaining = int( $space    / $hour );
    $self->trace("$name - $hour/hr. $stored of $capacity filled, ${remaining}hr of ${time}hr remaining");
  }

  return 1;
}

sub trace {
  print scalar(localtime time) . " - Summary - " . $_[1] . "\n";
}

1;
