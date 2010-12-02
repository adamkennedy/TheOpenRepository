package Games::Lacuna::Client::Buildings::Observatory;
use 5.0080000;
use strict;
use warnings;
use Carp 'croak';

use Games::Lacuna::Client;
use Games::Lacuna::Client::Buildings;

our @ISA = qw(Games::Lacuna::Client::Buildings);

sub api_methods {
  return {
    get_probed_stars => { default_args => [qw(session_id building_id)] },
    abandon_probe    => { default_args => [qw(session_id building_id)] },
  };
}

__PACKAGE__->init;






######################################################################
# Probe Integration

sub max_probes {
  my $self = shift;
  unless ( defined $self->{max_probes} ) {
    $self->fill_probes;
  }
  return $self->{max_probes};
}

sub star_count {
  my $self = shift;
  unless ( defined $self->{star_count} ) {
    $self->fill_probes;
  }
  return $self->{star_count};
}

sub probes {
  my $self = shift;
  unless ( defined $self->{stars} ) {
    $self->fill_probes;
  }
  return @{$self->{stars}};
}

sub fill_probes {
  my $self     = shift;
  my $response = $self->get_probed_stars;
  $self->{max_probes} = $response->{max_probes};
  $self->{star_count} = $response->{star_count};
  $self->{stars}      = $response->{stars};
  $self->set_status( $response->{status} );
  return $response;
}

sub probes_available {
  my $self = shift;
  return $self->max_probes - scalar $self->probes;
}

1;

__END__

=pod

=head1 NAME

Games::Lacuna::Client::Buildings::Observatory - The Observatory building

=head1 SYNOPSIS

  use Games::Lacuna::Client;

=head1 DESCRIPTION

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
