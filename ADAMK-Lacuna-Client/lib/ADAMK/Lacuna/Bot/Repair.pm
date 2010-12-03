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

  # Load the aggregate glyphs found
  $self->trace("Searching for damaged buildings");

  # Iterate over the bodies
  foreach my $planet ( $empire->planets ) {
    # Find damaged buildings, from cheap to expensive
    my @buildings = sort {
      $a->{level} <=> $b->{level}
    } grep {
      $_->{efficiency} < 100
    } $planet->buildings or next;

    # Just start attempting to repair
    foreach my $building ( @buildings ) {
        $self->trace(
            join ' ',
                "Attempting to repair level",
                $building->{level},
                $building->{name},
                "on planet",
                $planet->name,
        );
        $building->repair;
    }

    1;
  }

  return 1;
}

sub trace {
  print scalar(localtime time) . " - Repair - " . $_[1] . "\n";
}

1;
