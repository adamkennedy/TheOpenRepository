package ADAMK::Lacuna::Bot::Repair;

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

  # Iterate over the bodies
  foreach my $planet ( $empire->planets ) {
    # Find damaged buildings, from cheap to expensive
    my @buildings = sort {
      $a->{level} <=> $b->{level}
    } grep {
      $_->{efficiency} < 100
    } $planet->buildings or next;

    # Don't repair if we are in negative waste and empty
    if ( $planet->waste_hour < 0 and $planet->waste_stored < 10000 ) {
      next;
    }

    # Just start attempting to repair
    foreach my $building ( @buildings ) {
      my $message = join ' ',
        "Attempting to repair level",
        $building->{level},
        $building->{name},
        "on planet",
        $planet->name;
      $self->trace("ACTION($message)");
      $building->repair;
    }
  }

  return 1;
}

sub trace {
  print scalar(localtime time) . " - Repair - " . $_[1] . "\n";
}

1;
