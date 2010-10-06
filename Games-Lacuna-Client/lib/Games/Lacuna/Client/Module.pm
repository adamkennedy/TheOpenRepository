package Games::Lacuna::Client::Module;
use 5.010000;
use strict;
use warnings;
use Scalar::Util 'weaken';
use Carp 'croak';

use Class::XSAccessor {
  getters => [qw(client uri)],
};

require Games::Lacuna::Client;

sub api_methods_without_session { croak("unimplemented"); }
sub api_methods_with_session { croak("unimplemented"); }

sub module_prefix {
  my $self = shift;
  my $class = ref($self)||$self;
  $class =~ /::(\w+)+$/ or croak("unimplemented");
  return lc($1);
}

sub new {
  my $class = shift;
  my %opt = @_;
  my $client = $opt{client} || croak("Need Games::Lacuna::Client");
  
  my $self = bless {
    %opt,
  } => $class;
  weaken($self->{client});
  $self->{uri} = $self->client->uri . '/' . $self->module_prefix;
  
  return $self;
}

sub init {
  my $class = shift;

  Games::Lacuna::Client->_generate_methods_without_session($class, $class->api_methods_without_session);
  Games::Lacuna::Client->_generate_methods_with_session($class, $class->api_methods_with_session);
}



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
