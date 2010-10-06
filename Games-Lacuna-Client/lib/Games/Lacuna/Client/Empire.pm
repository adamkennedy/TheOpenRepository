package Games::Lacuna::Client::Empire;
use 5.010000;
use strict;
use warnings;
use Scalar::Util 'weaken';
use Carp 'croak';

use Games::Lacuna::Client;
use Games::Lacuna::Client::Module;
our @ISA = qw(Games::Lacuna::Client::Module);

sub api_methods_without_session {
  return qw(
    login
    is_name_available
    fetch_captcha
    found
    invite_friend
    send_password_reset_message
    reset_password
    change_password
    update_species
    get_species_templates
  );
}

sub api_methods_with_session {
  return qw(
    logout
    get_status
    view_profile
    edit_profile
    view_public_profile
    find
    set_status_message
    view_boosts
    boost_storage
    boost_food
    boost_water
    boost_energy
    boost_ore
    boost_happiness
    enable_self_destruct
    disable_self_destruct
    redeem_essentia_code
    view_species_stats
  );
}

sub logout {
  my $self = shift;
  my $client = $self->client;
  if (not $client->session_id) {
    return 0;
  }
  else {
    my $res = $self->_logout;
    return delete $client->{session_id};
  }
}

__PACKAGE__->init();

1;
__END__

=head1 NAME

Games::Lacuna::Client::Empire - The empire module

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
