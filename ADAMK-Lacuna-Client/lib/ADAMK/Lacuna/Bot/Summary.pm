package ADAMK::Lacuna::Bot::Summary;

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
  my $total  = $empire->resources;

  # Synthesize the derived values and summarise
  foreach my $type ( qw{ food ore water energy waste } ) {
    my $name     = ucfirst $type;
    my $hour     = $total->{"${type}_hour"};
    my $stored   = $total->{"${type}_stored"};
    my $capacity = $total->{"${type}_capacity"};
    my $space    = $total->{"${type}_space"};
    my $time     = int $total->{"${type}_time"};
    my $left     = int $total->{"${type}_left"};
    $self->trace("$name - $hour/hr. $stored of $capacity filled, ${left}hr of ${time}hr remaining");
  }

  return 1;
}

sub trace {
  print scalar(localtime time) . " - Summary - " . $_[1] . "\n";
}

1;
