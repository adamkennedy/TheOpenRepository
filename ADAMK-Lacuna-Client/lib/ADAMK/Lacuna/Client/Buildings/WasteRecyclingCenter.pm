package ADAMK::Lacuna::Client::Buildings::WasteRecyclingCenter;

use 5.008;
use strict;
use warnings;
use Carp 'croak';
use List::Util ();
use ADAMK::Lacuna::Client;
use ADAMK::Lacuna::Client::Buildings;

our $VERSION = '0.01';
our @ISA     = qw(ADAMK::Lacuna::Client::Buildings);

sub api_methods {
  return {
    view                => { default_args => [qw(session_id building_id)] },
    recycle             => { default_args => [qw(session_id building_id)] },
    subsidize_recycling => { default_args => [qw(session_id building_id)] },
  };
}

sub work_start {
  my $self = shift;
  return 0 unless $self->{work};
  return $self->{work}->{start};
}

sub work_end {
  my $self = shift;
  return 0 unless $self->{work};
  return $self->{work}->{end};
}

sub work_seconds_remaining {
  my $self = shift;
  return 0 unless $self->{work};
  return $self->{work}->{seconds_remaining};
}

sub busy {
  !! $_[0]->work_seconds_remaining;
}





######################################################################
# View/Status Methods

sub can_upgrade {
  $_[0]->status->{upgrade}->{can};
}

sub energy_capacity {
  $_[0]->status->{energy_capacity};
}

sub energy_hour {
  $_[0]->status->{energy_hour};
}

sub food_capacity {
  $_[0]->status->{food_capacity};
}

sub food_hour {
  $_[0]->status->{food_hour};
}

sub happiness_hour {
  $_[0]->status->{happiness_hour};
}

sub ore_capacity {
  $_[0]->status->{ore_capacity};
}

sub ore_hour {
  $_[0]->status->{ore_hour};
}

sub repair_costs {
  $_[0]->status->{repair_costs};
}

sub upgrade {
  $_[0]->status->{upgrade};
}

sub waste_capacity {
  $_[0]->status->{waste_capacity};
}

sub waste_hour {
  $_[0]->status->{waste_hour};
}

sub water_capacity {
  $_[0]->status->{water_capacity};
}

sub water_hour {
  $_[0]->status->{water_hour};
}

sub status {
  my $self = shift;
  unless ( defined $self->{status} ) {
    $self->fill;
  }
  return $self->{status};
}

sub fill {
  my $self     = shift;
  my $response = $self->view;
  $self->{status}            = $response->{building};
  $self->{status}->{recycle} = $response->{recycle};
  $self->set_status( $response->{status} );
  return $response;
}

sub flush {
  delete $_[0]->{status};
}





######################################################################
# Recycling Methods

sub can_recycle {
  $_[0]->status->{recycle}->{can};
}

sub max_recycle {
  $_[0]->status->{recycle}->{max_recycle};
}

sub seconds_per_resource {
  $_[0]->status->{recycle}->{seconds_per_resource};
}

__PACKAGE__->init;

1;

__END__

=pod

=head1 NAME

ADAMK::Lacuna::Client::Buildings::WasteRecycling - The Waste Recycling Center building

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
