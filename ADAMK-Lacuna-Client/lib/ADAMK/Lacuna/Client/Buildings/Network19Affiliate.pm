package ADAMK::Lacuna::Client::Buildings::Network19Affiliate;
use 5.0080000;
use strict;
use warnings;
use Carp 'croak';

use ADAMK::Lacuna::Client;
use ADAMK::Lacuna::Client::Buildings;

our @ISA = qw(ADAMK::Lacuna::Client::Buildings);

sub api_methods {
  return {
    view              => { default_args => [qw(session_id building_id)] },
    restrict_coverage => { default_args => [qw(session_id building_id)] },
    view_news         => { default_args => [qw(session_id building_id)] },
  };
}

__PACKAGE__->init();

1;
__END__

=head1 NAME

ADAMK::Lacuna::Client::Buildings::Network19Affiliate - The Network19 building

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
