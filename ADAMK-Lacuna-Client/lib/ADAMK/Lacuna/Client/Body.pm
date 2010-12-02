package ADAMK::Lacuna::Client::Body;

use 5.008;
use strict;
use warnings;
use List::Util                     ();
use ADAMK::Lacuna::Client          ();
use ADAMK::Lacuna::Client::Builder ();
use ADAMK::Lacuna::Client::Module  ();

our @ISA = qw{
  ADAMK::Lacuna::Client::Builder
  ADAMK::Lacuna::Client::Module
};

use Class::XSAccessor {
  getters => [ qw(
    client
    body
    body_id
    empire
  ) ],
};

sub api_methods {
  return {
    get_buildings => { default_args => [qw(session_id body_id)] },
    get_status    => { default_args => [qw(session_id body_id)] },
    get_buildable => { default_args => [qw(session_id body_id)] },
    rename        => { default_args => [qw(session_id body_id)] },
    abandon       => { default_args => [qw(session_id body_id)] },
  };
}

sub new {
  my $class = shift;
  my %opt   = @_;
  my $self  = $class->SUPER::new(@_);
  bless $self => $class;
  $self->{body_id} = $opt{id};
  return $self;
}

sub other_planets {
  my $self   = shift;
  my $empire = $self->empire;
  return map {
    $empire->planet($_)
  } $self->other_planet_ids;
}

sub other_planet_ids {
  my $self   = shift;
  my $empire = $self->empire;
  return grep {
    $_ != $self->body_id
  } $empire->planet_ids;
}

__PACKAGE__->init;

sub flush {
    delete $_[0]->{status};
    delete $_[0]->{buildings};
}





######################################################################
# Status Methods

__PACKAGE__->build_fillmethods( fill_buildings => 'status' );

__PACKAGE__->build_subaccessors( status => qw{
  building_count
  energy_capacity
  energy_hour
  energy_stored
  food_capacity
  food_hour
  food_stored
  happiness
  happiness_hour
  name
  orbit
  ore
  ore_capacity
  ore_hour
  ore_stored
  population
  size
  star_id
  star_name
  type
  waste_capacity
  waste_hour
  waste_stored
  water
  water_capacity
  water_hour
  water_stored
  x
  y
} );

sub set_status {
  my $self = shift;
  $self->{status} = shift;
  return 1;
}

sub energy_space {
  $_[0]->energy_capacity - $_[0]->energy_stored;
}

sub energy_remaining {
  int( $_[0]->energy_space / $_[0]->energy_hour * 3600 );
}

sub food_space {
  $_[0]->food_capacity - $_[0]->food_stored;
}

sub food_remaining {
  int( $_[0]->food_space / $_[0]->food_hour * 3600 );
}

sub ore_space {
  $_[0]->ore_capacity - $_[0]->ore_stored;
}

sub ore_remaining {
  int( $_[0]->ore_space / $_[0]->ore_hour * 3600 );
}

sub waste_space {
  $_[0]->waste_capacity - $_[0]->waste_stored;
}

sub waste_remaining {
  my $self = shift;
  if ( $self->waste_hour > 0 ) {
    return int(
      $self->waste_space / $self->waste_hour * 3600
    );
  } elsif ( $self->waste_hour < 0 ) {
    return int(
      $self->waste_stored / $self->waste_hour * 3600 * -1
    );
  } else {
    return 3600 * 24;
  }
}

sub water_space {
  $_[0]->water_capacity - $_[0]->water_stored;
}

sub water_remaining {
  int( $_[0]->water_space / $_[0]->water_hour * 3600 );
}





######################################################################
# Building Integration

sub buildings {
  my $self  = shift;
  my %param = @_;

  # Populate the buildings if needed
  unless ( defined $self->{buildings} ) {
    $self->fill_buildings;
  }

  # Convert to a simple list
  my @list = map {
    $self->{buildings}->{$_}
  } sort keys %{$self->{buildings}};

  # Filter by name
  if ( $param{name} ) {
    @list = grep { $_->name eq $param{name} } @list;
  }

  return @list;
}

sub building {
  $_[0]->buildings->{$_[1]};
}

sub building_named {
  ($_[0]->buildings( name => $_[1] ))[0];
}

sub fill_buildings {
  my $self     = shift;
  my $client   = $self->client;
  my $response = $self->get_buildings;

  # Save the bundled status information
  my $status = $response->{status};
  if ( $self->empire ) {
    $self->empire->set_status( $status->{empire} );
  }
  $self->{status}    = $status->{body};
  $self->{buildings} = $response->{buildings};

  # Upgrade the building hashes into objects
  foreach my $id ( sort keys %{ $self->{buildings} } ) {
    my $hash = $self->{buildings}->{$id};

    # Create the full object
    my $object = $client->building(
      id   => $id,
      type => $hash->{name},
      body => $self,
      %{ $hash },
    ) or die "Failed to create '$hash->{name}' building $id";

    $self->{buildings}->{$id} = $object;
  }

  return 1;
}

sub pending_build {
  my $self = shift;
  return List::Util::max map {
    $_->{pending_build}->{seconds_remaining}
  } grep {
    $_->{pending_build}
  } $self->buildings;
}

sub pending_builds {
  return grep {
    $_->{pending_build}
  } $_[0]->buildings;
}





######################################################################
# Single-Instance Buildings

sub archaeology_ministry {
  $_[0]->building_named('Archaeology Ministry');
}

sub capitol {
  $_[0]->building_named('Capitol');
}

sub cloaking_lab {
  $_[0]->building_named('Cloaking Lab');
}

sub development_ministry {
  $_[0]->building_named('Development Ministry');
}

sub embassy {
  $_[0]->building_named('Embassy');
}

sub espionage_ministry {
  $_[0]->building_named('Espionage Ministry');
}

sub intelligence_ministry {
  $_[0]->building_named('Intelligence Ministry');
}

sub mining_ministry {
  $_[0]->building_named('Mining Ministry');
}

sub mission_command {
  $_[0]->building_named('Mission Command');
}

sub network_19_affiliate {
  $_[0]->building_named('Network 19 Affiliate');
}

sub observatory {
  $_[0]->building_named('Observatory');
}

sub oversight_ministry {
  $_[0]->building_named('Oversight Ministry');
}

sub pilot_training_facility {
  $_[0]->building_named('Pilot Training Facility');
}

sub planetary_command_center {
  $_[0]->building_named('Planetary Command Center');
}

sub propulsion_system_factory {
  $_[0]->building_named('Propulsion System Factory');
}

sub security_ministry {
  $_[0]->building_named('Security Ministry');
}

sub stockpile {
  $_[0]->building_named('Stockpile');
}

sub subspace_transporter {
  $_[0]->building_named('Subspace Transporter');
}

sub trade_ministry {
  $_[0]->building_named('Trade Ministry');
}

sub university {
  $_[0]->building_named('University');
}





######################################################################
# Multiple-Instance Buildings

sub space_port {
  ($_[0]->space_ports)[0];
}

sub space_ports {
  $_[0]->buildings( name => 'Space Port' );
}

sub waste_sequestration_wells {
  $_[0]->buildings( name => 'Waste Sequestration Well' );
}

sub waste_recycling_centers {
  $_[0]->buildings( name => 'Waste Recycling Center' );
}





######################################################################
# Multi-Spaceport Ship Abstraction

# All space ports show all ships for all other space ports
sub ships {
  my $self = shift;
  my $port = $self->space_port;
  return map { $_->ships(@_) } ( $port || () );
}

# Cargo ships are always preferable from biggest to smallest,
# and fastest to slowest.
sub cargo_ships {
  return sort {
    $b->{hold_size} <=> $a->{hold_size}
    or
    $b->{speed} <=> $a->{speed}
  } $_[0]->ships(
    type => 'Cargo Ship',
    task => 'Docked',
  );
}

# What is the best unused cargo ship on the planet
sub best_cargo_ship {
  my @cargo = grep {
    not defined $_->{date_available}
  } $_[0]->cargo_ships;
  return $cargo[0];
}

sub push_items {
  my $self     = shift;
  my $target   = shift;
  my $trade    = $self->trade_ministry or return;
  my $response = $trade->push_items( $target->body_id, @_ );
  $trade->flush;
  $self->flush;
  return $response;
}





######################################################################
# Planet-Level Spy Integration

sub spies {
  my $self     = shift;
  my %param    = @_;
  my $ministry = $self->intelligence_ministry or return ();
  my @spies    = $ministry->spies;

  # Apply filters
  if ( $param{name} ) {
    @spies = grep { $_->name eq $param{name} } @spies;
  }

  return @spies;
}

1;

__END__

=pod

=head1 NAME

ADAMK::Lacuna::Client::Body - The body module

=head1 SYNOPSIS

  use ADAMK::Lacuna::Client;

=head1 DESCRIPTION

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
