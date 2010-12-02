package ADAMK::Lacuna::Client::Buildings::MiningMinistry;

use 5.008;
use strict;
use warnings;
use Carp 'croak';

use ADAMK::Lacuna::Client;
use ADAMK::Lacuna::Client::Buildings;

our @ISA = qw(ADAMK::Lacuna::Client::Buildings);

sub api_methods {
  return {
    view                         => { default_args => [qw(session_id building_id)] },
    view_ships                   => { default_args => [qw(session_id building_id)] },
    view_platforms               => { default_args => [qw(session_id building_id)] },
    abandon_platform             => { default_args => [qw(session_id building_id)] },
    add_cargo_ship_to_fleet      => { default_args => [qw(session_id building_id)] },
    remove_cargo_ship_from_fleet => { default_args => [qw(session_id building_id)] },
  };
}

__PACKAGE__->init;





######################################################################
# Platform Integration

sub platforms {
  my $self = shift;
  unless ( defined $self->{platforms} ) {
    $self->fill_platforms;
  }
  return @{ $self->{platforms} };
}

sub max_platforms {
  my $self = shift;
  unless ( defined $self->{max_platforms} ) {
    $self->fill_platforms;
  }
  return $self->{max_platforms};
}

sub fill_platforms {
  my $self     = shift;
  my $response = $self->view_platforms;
  $self->{max_platforms} = $response->{max_platforms};
  $self->{platforms}     = $response->{platforms};
  $self->set_status( $response->{status} );
  return $response;
}

sub platforms_available {
  my $self = shift;
  return $self->max_platforms - scalar $self->platforms;
}

sub shipping_capacity {
  my $self     = shift;
  my @capacity = map { $_->{shipping_capacity} } $self->platforms;
  if ( @capacity ) {
    return $capacity[0];
  } else {
    return 0;
  }
}





######################################################################
# Ship Integration

sub ships {
  my $self = shift;
  unless ( defined $self->{ships} ) {
    $self->fill_ships;
  }
  return $self->{ships};
}

sub fill_ships {
  my $self     = shift;
  my $response = $self->view_ships;
  $self->{ships} = $response->{ships};
  $self->set_status( $response->{status} );
  return $response;
}

1;

__END__

=pod

=head1 NAME

ADAMK::Lacuna::Client::Buildings::MiningMinistry - The Mining Ministry building

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
