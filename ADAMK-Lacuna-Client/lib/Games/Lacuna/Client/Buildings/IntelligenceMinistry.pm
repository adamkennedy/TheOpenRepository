package Games::Lacuna::Client::Buildings::IntelligenceMinistry;

use 5.0080000;
use strict;
use warnings;
use Carp 'croak';

use Games::Lacuna::Client;
use Games::Lacuna::Client::Buildings;
use Games::Lacuna::Client::Spy;

our @ISA = qw(Games::Lacuna::Client::Buildings);

sub module_prefix {
  return 'intelligence';
}

sub api_methods {
  return {
    view                  => { default_args => [qw(session_id building_id)] },
    train_spy             => { default_args => [qw(session_id building_id)] },
    view_spies            => { default_args => [qw(session_id building_id)] },
    subsidize_training    => { default_args => [qw(session_id building_id)] },
    burn_spy              => { default_args => [qw(session_id building_id)] },
    name_spy              => { default_args => [qw(session_id building_id)] },
    assign_spy            => { default_args => [qw(session_id building_id)] },
  };
}

__PACKAGE__->init;





######################################################################
# Spy Integration

sub spies {
  my $self     = shift;
  my $response = $self->view_spies;
  $self->set_status( $response->{status} );
  return map {
    Games::Lacuna::Client::Spy->new( %$_, building => $self )
  } @{ $response->{spies} };
}

1;

__END__

=pod

=head1 NAME

Games::Lacuna::Client::Buildings::IntelligenceMinistry - The Intelligence Ministry building

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
