package ADAMK::Lacuna::Client::Module;

use 5.008;
use strict;
use warnings;
use Carp 'croak';

use Class::XSAccessor {
  getters => [ qw(
    client
    url
  ) ],
};

sub api_methods_without_session {
  croak("unimplemented");
}

sub api_methods_with_session {
  croak("unimplemented");
}

sub module_prefix {
  my $self = shift;
  my $class = ref($self)||$self;
  $class =~ /::(\w+)+$/ or croak("unimplemented");
  return lc($1);
}

sub session_id {
  $_[0]->client->assert_session;
}

sub new {
  my $class  = shift;
  my $self   = bless { @_ }, $class;
  my $client = $self->{client} || croak("Need ADAMK::Lacuna::Client");
  my $suffix = $self->{url} || $self->module_prefix;
  $suffix =~ s/\///;
  $self->{url} = $self->client->uri . '/' . $suffix;
  return $self;
}

sub init {
  my $class = shift;
  $class->_generate_api_methods( $class->api_methods );
}

sub _generate_api_methods {
  my $class        = shift;
  my $method_specs = shift || croak("Missing method specs");

  foreach my $method_name (keys %$method_specs) {
    my $target = $class->_find_target_name($method_name);
    my $spec = $method_specs->{$method_name};
    $class->_generate_method_per_spec($target, $method_name, $spec);
  }
}

sub _generate_method_per_spec {
  my $class        = shift;
  my $target       = shift;
  my $method_name  = shift;
  my $spec         = shift;
  my $default_args = $spec->{default_args};

  my $sub = sub {
    my $self = shift;
    my $client = $self->client;

    # prepend the default parameters to the arguments
    my $params = [
      (map $self->$_(), @$default_args),
      @_
    ];

    if ( $client->debug ) {
      print "DEBUG: " . __PACKAGE__ . " request " . Data::Dumper::Dumper([$self->uri, $method_name, $params]);
    }
    my $ret = $client->rpc->call( $self->url, $method_name, $params );
    if ( $client->debug ) {
      print "DEBUG: " . __PACKAGE__ . " result " . Data::Dumper::Dumper($ret);
    }
    return $ret->{result};
  };

  no strict 'refs';
  *{"$target"} = $sub;  
}

sub _find_target_name {
  my $class = shift;
  my $method_name = shift;
  no strict 'refs';
  my $target = "${class}::$method_name";
  if (defined &{"$target"}) {
    $target = "${class}::_$method_name";
  }
  return $target;
}





######################################################################
# Optional Code Generators

sub build_subaccessors {
	my $class   = shift;
	my $method  = shift;
	my $methods = join "\n\n", map { <<"END_PERL" } @_;
sub $_ {
  shift->${method}->{'$_'};
}
END_PERL
	eval "package $class;\n\n$methods\n\n1;\n";
	die "Failed to compile code: $@" if $@;

	return 1;
}

1;

__END__

=pod

=head1 NAME

ADAMK::Lacuna::Client::Empire - The empire module

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
