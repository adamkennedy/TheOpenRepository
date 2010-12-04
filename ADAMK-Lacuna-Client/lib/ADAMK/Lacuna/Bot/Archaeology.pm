package ADAMK::Lacuna::Bot::Archaeology;

use 5.008;
use strict;
use warnings;
use List::Util                 ();
use Params::Util               ();
use ADAMK::Lacuna::GlyphDB     ();
use ADAMK::Lacuna::Bot::Plugin ();

our $VERSION = '0.01';
our @ISA     = 'ADAMK::Lacuna::Bot::Plugin';

sub priority {
  my $self = shift;
  return ADAMK::Lacuna::GlyphDB->priority2glyphs unless $self->{prefer};
  return ADAMK::Lacuna::GlyphDB->priority2glyphs($self->{prefer});
}

sub run {
  my $self   = shift;
  my $client = shift;
  my $empire = $client->empire;

  # Determine the supply/demand ratio for glyphs, based on the aggregate
  # glyphs we have vs the priority weights.
  $self->trace("Calculating glyph priority");
  my $have  = $empire->glyphs_count;
  my $want  = $self->priority;
  my %ratio = map {
    $_ => (($have->{$_} || 0) / $want->{$_})
  } grep {
    $want->{$_}
  } ADAMK::Lacuna::GlyphDB->glyphs;

  # Iterate over the bodies
  foreach my $planet ( $empire->planets ) {
    my $name = $planet->name;

    # Does the planet have an Archaeology Ministry?
    my $ministry = $planet->archaeology_ministry;
    next unless $ministry;
    next unless $ministry->level >= 5;
    next if $ministry->busy;

    # Which ore do we have the least glyphs for
    $self->trace("$name - Checking for available ores");
    my $ore  = $ministry->ores;
    my %here = map { $_ => $have->{$_} || 0 } keys %$ore;

    # Search for the ore we have the worst supply/demand balance of
    # and tie-break on the rarest ore that we have at hand.
    my @ores = grep { $ore->{$_} >= 10000 } keys %$ore or next;
    my @best = grep { defined $ratio{$_} } @ores;
    @best = @ores unless @best;
    @best = sort {
      $ratio{$a} <=> $ratio{$a}
      or
      $want->{$b} <=> $want->{$a}
      or
      $ore->{$a} <=> $ore->{$b}
    } @best;

    # Execute the archaeological search
    $self->trace("$name - TAKING ACTION(Searching $ores[0] ore)");
    $ministry->search_for_glyph($best[0]);
  }

  # Summarise what we can build if we wanted
  my $buildable = ADAMK::Lacuna::GlyphDB->glyphs2buildable(%$have);
  if ( %$buildable ) {
    $self->trace("Build Possibilities:");
    foreach my $name ( sort keys %$buildable ) {
      $self->trace("$buildable->{$name} x $name");
    }
  }

  return 1;
}

1;
