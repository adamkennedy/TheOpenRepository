package Games::Lacuna::Client::Stats;
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
    credits
  );
}

sub api_methods_with_session {
  return qw(
    alliance_rank
    find_alliance_rank
    empire_rank
    find_empire_rank
    colony_rank
    spy_rank
    weekly_medal_winners
  );
}

__PACKAGE__->init();

1;
__END__

=head1 NAME

Games::Lacuna::Client::Stats - The server stats module

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
