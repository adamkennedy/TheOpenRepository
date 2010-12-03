package ADAMK::Lacuna::Client::Buildings::SpacePort;

use 5.008;
use strict;
use warnings;
use ADAMK::Lacuna::Client;
use ADAMK::Lacuna::Client::Builder;
use ADAMK::Lacuna::Client::Buildings;
use ADAMK::Lacuna::Client::Ship;

our @ISA = qw{
  ADAMK::Lacuna::Client::Builder
  ADAMK::Lacuna::Client::Buildings
};

sub api_methods {
  return {
    view                    => { default_args => [qw(session_id building_id)] },
    view_all_ships          => { default_args => [qw(session_id building_id)] },
    view_foreign_ships      => { default_args => [qw(session_id building_id)] },
    get_ships_for           => { default_args => [qw(session_id)] },
    send_ship               => { default_args => [qw(session_id)] },
    name_ship               => { default_args => [qw(session_id building_id)] },
    scuttle_ship            => { default_args => [qw(session_id building_id)] },
    view_ships_travelling   => { default_args => [qw(session_id building_id)] },
    prepare_send_spies      => { default_args => [qw(session_id)] },
    send_spies              => { default_args => [qw(session_id)] },
    prepare_fetch_spies     => { default_args => [qw(session_id)] },
    fetch_spies             => { default_args => [qw(session_id)] },
  };
}

__PACKAGE__->init;

sub flush {
  my $self = shift;
  delete $self->{docked_ships};
  delete $self->{docks_available};
  delete $self->{max_ships};
  delete $self->{status};
  delete $self->{number_of_ships};
  delete $self->{ships};
  return 1;
}





######################################################################
# View Integration

__PACKAGE__->build_fillmethods( fill_view => qw{
  docked_ships
  docks_available
  max_ships
} );

sub fill_view {
  my $self     = shift;
  my $response = $self->view;
  $self->{status}          = $response->{building};
  $self->{docked_ships}    = $response->{docked_ships};
  $self->{docks_available} = $response->{docks_available};
  $self->{max_ships}       = $response->{max_ships};
  $self->set_status( $response->{status} );
  return $response;
}





######################################################################
# Ship Integration

__PACKAGE__->build_fillmethods( fill_ships => qw{
  number_of_ships
} );

sub ships {
  my $self   = shift;
  my %filter = @_;
  unless ( defined $self->{ships} ) {
    $self->fill_ships;
  }
  my @ships = @{$self->{ships}};
  if ( $filter{task} ) {
    @ships = grep { $_->task eq $filter{task} } @ships;
  }
  if ( $filter{type} ) {
    @ships = grep { $_->type_human eq $filter{type} } @ships;
  }
  return @ships;
}

sub fill_ships {
  my $self     = shift;
  my $response = $self->all_ships;
  $self->set_status( $response->{status} );
  $self->{number_of_ships} = $response->{number_of_ships};

  # Convert the ships into objects
  my @ships = map {
    ADAMK::Lacuna::Client::Ship->new(
      %$_,
      spaceport => $self,
    )
  } @{$response->{ships}};

  $self->{ships} = \@ships;
  return $response;
}

sub all_ships {
  my $self     = shift;
  my $response = $self->view_all_ships(1);
  my $ships    = $response->{number_of_ships};
  my $pages    = int($ships / 25) + 1;
  foreach ( 2 .. $pages ) {
    my $append = $self->view_all_ships($_);
    push @{$response->{ships}}, @{$append->{ships}};
  }
  return $response;
}

1;

__END__

=head1 NAME

ADAMK::Lacuna::Client::Buildings::SpacePort - The Space Port building

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
