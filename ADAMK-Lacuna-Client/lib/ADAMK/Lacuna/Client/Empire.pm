package ADAMK::Lacuna::Client::Empire;

use 5.008;
use strict;
use warnings;
use ADAMK::Lacuna::Client;
use ADAMK::Lacuna::Client::Module;
use ADAMK::Lacuna::Client::Body;

our @ISA = qw(ADAMK::Lacuna::Client::Module);

use Class::XSAccessor {
  getters => [qw(
    client
    empire_id
  )],
};

sub api_methods {
  return {
    login                       => { default_args => [ ] },
    is_name_available           => { default_args => [ ] },
    fetch_captcha               => { default_args => [ ] },
    send_password_reset_message => { default_args => [ ] },
    reset_password              => { default_args => [ ] },
    get_species_templates       => { default_args => [ ] },
    found                       => { default_args => [qw(empire_id)] },
    update_species              => { default_args => [qw(empire_id)] },
    invite_friend               => { default_args => [qw(session_id)] },
    change_password             => { default_args => [qw(session_id)] },
    logout                      => { default_args => [qw(session_id)] },
    get_status                  => { default_args => [qw(session_id)] },
    view_profile                => { default_args => [qw(session_id)] },
    edit_profile                => { default_args => [qw(session_id)] },
    view_public_profile         => { default_args => [qw(session_id empire_id)] },
    find                        => { default_args => [qw(session_id)] },
    set_status_message          => { default_args => [qw(session_id)] },
    view_boosts                 => { default_args => [qw(session_id)] },
    boost_storage               => { default_args => [qw(session_id)] },
    boost_food                  => { default_args => [qw(session_id)] },
    boost_water                 => { default_args => [qw(session_id)] },
    boost_energy                => { default_args => [qw(session_id)] },
    boost_ore                   => { default_args => [qw(session_id)] },
    boost_happiness             => { default_args => [qw(session_id)] },
    enable_self_destruct        => { default_args => [qw(session_id)] },
    disable_self_destruct       => { default_args => [qw(session_id)] },
    redeem_essentia_code        => { default_args => [qw(session_id)] },
    view_species_stats          => { default_args => [qw(session_id)] },
  };
}

sub new {
  my $class = shift;
  my %opt   = @_;
  my $self  = $class->SUPER::new(%opt);
  bless $self => $class;
  $self->{empire_id} = $opt{id};
  return $self;
}

sub logout {
  my $self = shift;
  my $client = $self->client;
  unless ( $client->session_id ) {
    return 0;
  }
  my $res = $self->_logout;
  return delete $client->{session_id};
}

__PACKAGE__->init;





######################################################################
# Status Methods

sub status {
  my $self = shift;
  unless ( defined $self->{status} ) {
    my $response = $self->get_status;
    unless ( $response->{empire} ) {
        die "Missing expected field";
    }
    $self->{status} = $response->{empire};
  }
  return $self->{status};
}

sub set_status {
  my $self = shift;
  $self->{status} = shift;
  return 1;
}

sub name {
  $_[0]->status->name;
}

__PACKAGE__->build_subaccessors( status => qw{
	essentia
	home_planet_id
	id
	is_isolationist
} );





######################################################################
# Species Integration

sub species {
	my $self = shift;
	unless ( $self->{species} ) {
		$self->fill_species;
	}
	return $self->{species};
}

sub fill_species {
	my $self     = shift;
	my $response = $self->view_species_stats;
	$self->set_status( $response->{status} );
	$self->{species} = $response->{species};
	return $response;
}

__PACKAGE__->build_subaccessors( species => qw{
	min_orbit
	max_orbit
	manufacturing_affinit
	deception_affinity
	research_affinity
	management_affinity
	farming_affinity
	mining_affinity
	science_affinity
	environmental_affinity
	political_affinity
	trade_affinity
	growth_affinity
} );





######################################################################
# Planet Integration

sub planet_ids {
  my $self    = shift;
  my $planets = $self->status->{planets};
  return sort { $planets->{$a} cmp $planets->{$b} } keys %$planets;
}

sub planets {
  my $self = shift;
  return map { $self->planet($_) } $self->planet_ids;
}

sub planet {
  my $self = shift;
  my $id   = shift;
  unless ( defined $self->{planets} ) {
    $self->{planets} = {};
  }
  unless ( defined $self->{planets}->{$id} ) {
    my $body = $self->client->body(
      id     => $id,
      empire => $self,
    ) or die "Failed to find body $id";
    $self->{planets}->{$id} = $body;
  }
  return $self->{planets}->{$id};
}

sub home_planet {
  my $self = shift;
  $self->planet( $self->home_planet_id );
}





######################################################################
# Empire-wide Aggregation

# Status values that can be directly added up
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

sub resources {
  my $self = shift;

  # Iterate over all planets and total the common resources
  my %total = ();
  foreach my $planet ( $self->planets ) {
    foreach my $method ( @ADDABLE ) {
      $total{$method} = 0 unless defined $total{$method};
      $total{$method} += $planet->$method();
    }
  }

  # Derive the remaining values
  foreach my $type ( qw{ food ore water energy waste } ) {
    $total{"${type}_space"} = $total{"${type}_capacity"} - $total{"${type}_stored"};
    $total{"${type}_time"}  = $total{"${type}_capacity"} / $total{"${type}_hour"};
    $total{"${type}_left"}  = $total{"${type}_space"}    / $total{"${type}_space"};
  }

  return \%total;
}

# Determine the order in which we are most interested in increasing our
# resource supply. Assuming that capacity limits are boosted approximately
# when that resource is more greatly needed, we can take the number of hours
# remaining until we fill all storage to capacity as the resource we are most
# in need of.
sub resource_priority {
  my $self  = shift;
  my $total = $self->resources;
  my %left  = (
    food   => $total->{food_left},
    ore    => $total->{ore_left},
    water  => $total->{water_left},
    energy => $total->{energy_left},
  );
  return sort {
    $left{$b} <=> $left{$a}
  } keys %left;
}

sub spy {
  my $self  = shift;
  my @spies = $self->spies( @_ );
  die 'Failed to find spy' unless @spies;
  die 'Found too many spies' if @spies > 1;
  return $spies[0];
}

sub spies {
  my $self  = shift;
  my %param = @_;
  return map { $_->spies(%param) } $self->planets;
}

sub glyphs_count {
  my $self  = shift;
  my %total = ();

  foreach my $planet ( $self->planets ) {
    my $ministry = $planet->archaeology_ministry or next;
    my $have     = $ministry->glyphs_count;
    foreach my $type ( keys %$have ) {
      $total{$type} += $have->{$type};
    }
  }

  return \%total;
}

1;

__END__

=pod

=head1 NAME

ADAMK::Lacuna::Client::Empire - The empire module

=head1 SYNOPSIS

  use ADAMK::Lacuna::Client;
  use ADAMK::Lacuna::Client::Empire;
  
  my $client = ADAMK::Lacuna::Client->new(...);
  my $empire = $client->empire;
  
  my $status = $empire->get_status;

=head1 DESCRIPTION

A subclass of L<ADAMK::Lacuna::Client::Module>.

=head2 new

Creates an object locally, does not connect to the server.

  ADAMK::Lacuna::Client::Empire->new( client => $client, @parameters );

The $client is a C<ADAMK::Lacuna::Client> object.

Usually, you can just use the C<empire> factory method of the
client object instead:

  my $empire = $client->empire(@parameters); # client set automatically

Optional parameters:

  id => "The id of the empire"

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
