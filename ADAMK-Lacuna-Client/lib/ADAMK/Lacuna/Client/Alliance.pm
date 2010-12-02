package ADAMK::Lacuna::Client::Alliance;
use 5.0080000;
use strict;
use warnings;
use Carp 'croak';

use ADAMK::Lacuna::Client;
use ADAMK::Lacuna::Client::Module;
our @ISA = qw(ADAMK::Lacuna::Client::Module);

use Class::XSAccessor {
  getters => [qw(alliance_id)],
};

sub api_methods {
  return {
    find         => { default_args => [qw(session_id)] },
    view_profile => { default_args => [qw(session_id alliance_id)] },
  };
}

sub new {
  my $class = shift;
  my %opt = @_;
  my $self = $class->SUPER::new(@_);
  bless $self => $class;
  $self->{alliance_id} = $opt{id};
  return $self;
}

__PACKAGE__->init();

1;
__END__

=head1 NAME

ADAMK::Lacuna::Client::Alliance - The alliance module

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
