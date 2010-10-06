package Games::Lacuna::Client::Map;
use 5.010000;
use strict;
use warnings;
use Scalar::Util 'weaken';
use Carp 'croak';

use Games::Lacuna::Client;
use Games::Lacuna::Client::Module;
our @ISA = qw(Games::Lacuna::Client::Module);

sub api_methods_without_session {
  return qw();
}

sub api_methods_with_session {
  return qw(
    get_stars
    check_star_for_incoming_probe
    get_star
    get_star_by_name
    get_star_by_xy
    search_stars
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

Games::Lacuna::Client::Map - The map module

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
