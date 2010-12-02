package ADAMK::Lacuna::Client::Spy;

use 5.008;
use strict;
use warnings;

use Class::XSAccessor {
  getters => [ qw(
    building
    assignment
    defense_rating
    id
    intel
    is_available
    level
    mayhem
    name
    offense_rating
    politics
    seconds_remaining
    theft
  ) ],
};

sub new {
  my $class = shift;
  my $self  = bless { @_ }, $class;
  return $self;
}

sub client {
  $_[0]->body->client;
}

sub body {
  $_[0]->building->body;
}

sub empire {
  $_[0]->building->body->empire;
}

sub assigned_to {
  my $self   = shift;
  my $client = $self->client;
  my $id     = $self->{assigned_to}->{body_id};
  my $body   = $client->body(
    id => $id,
  ) or die "Failed to find body $id";
  return $body;
}





######################################################################
# Spy Math

sub deception {
  $_[0]->empire->deception_affinity;
}

sub espionage {
  $_[0]->body->espionage_ministry ? $_[0]->body->espionage_ministry->level : 0;
}

sub security {
  $_[0]->body->security_ministry ? $_[0]->body->security_ministry->level : 0;
}

sub offense {
  ($_[0]->espionage * 75) + ($_[0]->deception * 50);
}

sub defense {
  ($_[0]->security * 75) + ($_[0]->deception * 50);
}

sub base {
  return 200;
}

sub mylevel {
  my $self  = shift;
  my $total = $self->offense
            + $self->defense
            + $self->intel
            + $self->mayhem
            + $self->theft
            + $self->politics;
  return int( $total / $self->base );
}

sub intel_power {
  $_[0]->offense + $_[0]->intel;
}

sub mayhem_power {
  $_[0]->offense + $_[0]->mayhem;
}

sub theft_power {
  $_[0]->offense + $_[0]->theft;
}

sub politics_power {
  $_[0]->offense + $_[0]->politics;
}

sub intel_toughness {
  $_[0]->defense + $_[0]->intel;
}

sub mayhem_toughness {
  $_[0]->defense + $_[0]->mayhem;
}

sub theft_toughness {
  $_[0]->defense + $_[0]->theft;
}

sub politics_toughness {
  $_[0]->defense + $_[0]->politics;
}

1;
