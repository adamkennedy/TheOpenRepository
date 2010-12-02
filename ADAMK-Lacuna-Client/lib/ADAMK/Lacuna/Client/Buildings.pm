package ADAMK::Lacuna::Client::Buildings;

use 5.008;
use strict;
use warnings;
use Carp 'croak';
use ADAMK::Lacuna::Client;
use ADAMK::Lacuna::Client::Module;

our @ISA = qw(ADAMK::Lacuna::Client::Module);

require ADAMK::Lacuna::Client::Buildings::Simple;
require ADAMK::Lacuna::Client::Buildings::ArchaeologyMinistry;
require ADAMK::Lacuna::Client::Buildings::DevelopmentMinistry;
require ADAMK::Lacuna::Client::Buildings::Embassy;
require ADAMK::Lacuna::Client::Buildings::IntelligenceMinistry;
require ADAMK::Lacuna::Client::Buildings::MiningMinistry;
require ADAMK::Lacuna::Client::Buildings::Network19Affiliate;
require ADAMK::Lacuna::Client::Buildings::Observatory;
require ADAMK::Lacuna::Client::Buildings::Park;
require ADAMK::Lacuna::Client::Buildings::PlanetaryCommandCenter;
require ADAMK::Lacuna::Client::Buildings::SecurityMinistry;
require ADAMK::Lacuna::Client::Buildings::Shipyard;
require ADAMK::Lacuna::Client::Buildings::SpacePort;
require ADAMK::Lacuna::Client::Buildings::TradeMinistry;
require ADAMK::Lacuna::Client::Buildings::SubspaceTransporter;
require ADAMK::Lacuna::Client::Buildings::WasteRecyclingCenter;

use Class::XSAccessor {
  getters => [ qw(
    body
    building_id
    efficiency
    level
    name
    url
    x
    y
  ) ],
};

sub api_methods {
  return {
    build               => { default_args => [qw(session_id)] },
    view                => { default_args => [qw(session_id building_id)] },
    upgrade             => { default_args => [qw(session_id building_id)] },
    demolish            => { default_args => [qw(session_id building_id)] },
    downgrade           => { default_args => [qw(session_id building_id)] },
    get_stats_for_level => { default_args => [qw(session_id building_id)] },
    repair              => { default_args => [qw(session_id building_id)] },
  };
}

sub new {
  my $class = shift;
  $class    = ref($class)||$class;
  my %opt   = @_;
  my $btype = delete $opt{type};

  # Redispatch in factory mode
  if ( defined $btype ) {
    $btype =~ s/\s//g;
    if ( $class ne 'ADAMK::Lacuna::Client::Buildings' ) {
      croak("Cannot call ->new on ADAMK::Lacuna::Client::Buildings subclass ($class) and pass the 'type' parameter");
    }
    my $realclass = "ADAMK::Lacuna::Client::Buildings::$btype";
    return $realclass->new(%opt);
  }

  my $id   = delete $opt{id};
  my $self = $class->SUPER::new(%opt);
  $self->{building_id} = $id;

  # We could easily support the body_id as default argument for ->build
  # here, but that would mean you had to specify the body_id at build time
  # or require building construction via $body->building(...)
  # Let's keep it simple for now.
  # $self->{body_id} = $opt{body_id};

  bless $self => $class;
  return $self;
}

sub empire {
  $_[0]->body->empire;
}

sub build {
  my $self = shift;
  my $rv   = $self->_build(@_);
  $self->{building_id} = $rv->{building}->{id};
  return $rv;
}

sub set_status {
  my $self   = shift;
  my $status = shift or return 1;
  if ( $status->{body} ) {
    $self->body->set_status( $status->{body} );
  }
  if ( $status->{empire} ) {
    $self->empire->set_status( $status->{empire} );
  }
  return 1;
}

__PACKAGE__->init;

1;

__END__

=pod

=head1 NAME

ADAMK::Lacuna::Client::Buildings - The buildings module

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
