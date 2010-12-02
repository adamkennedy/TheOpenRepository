package ADAMK::Lacuna::Client::Buildings::DevelopmentMinistry;

use 5.008;
use strict;
use warnings;
use Carp 'croak';

use ADAMK::Lacuna::Client;
use ADAMK::Lacuna::Client::Buildings;

our @ISA = qw(ADAMK::Lacuna::Client::Buildings);

sub api_methods {
  return {
    view                  => { default_args => [qw(session_id building_id)] },
    subsidize_build_queue => { default_args => [qw(session_id building_id)] },
  };
}

__PACKAGE__->init();

1;

__END__

=pod

=head1 NAME

ADAMK::Lacuna::Client::Buildings::Development - The Development Ministry building

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
