package ADAMK::Lacuna::Bot::Archaeology;

use 5.008;
use strict;
use warnings;
use List::Util                 ();
use Params::Util               ();
use ADAMK::Lacuna::Bot::Plugin ();

our $VERSION = '0.01';
our @ISA     = 'ADAMK::Lacuna::Bot::Plugin';

sub prefer {
  my $self = shift;
  if ( $self->{prefer} ) {
    return @{$self->{prefer}};
  } else {
    return ();
  }
}

sub run {
  my $self   = shift;
  my $client = shift;
  my $empire = $client->empire;

  # Load the aggregate glyphs found
  $self->trace("Counting all existing glyphs");
  my $have = $empire->glyphs_count;

  # Iterate over the bodies
  foreach my $planet_id ( $empire->planet_ids ) {
    my $planet = $empire->planet($planet_id);
    my $name   = $planet->name;
    $self->trace("Checking planet $name");

    # Does the planet have an Archaeology Ministry?
    my $ministry = $planet->archaeology_ministry;
    next unless $ministry;
    next unless $ministry->level >= 5;
    next if $ministry->busy;

    # Which ore do we have the least glyphs for
    $self->trace("$name - Checking for available ores");
    my $ore  = $ministry->ores;
    my %here = map { $_ => $have->{$_} || 0 } keys %$ore;

    # Search for the glyph we have the least of, and tie
    # break by searching the rarest ore we have here.
    my @ores = sort {
      $here{$a} <=> $here{$b}
      or
      $ore->{$a} <=> $ore->{$b}
    } grep {
      $ore->{$_} > 10000
    } keys %$ore or next;

    # Execute the archaeological search
    $self->trace("$name - TAKING ACTION(Searching $ores[0] ore)");
    eval {
      $ministry->search_for_glyph($ores[0]);
    };
    if ( $@ ) {
      $self->trace("$name - ERROR $@");
    }
  }

  return 1;
}

sub trace {
  print scalar(localtime time) . " - Archaeology - " . $_[1] . "\n";
}

1;
