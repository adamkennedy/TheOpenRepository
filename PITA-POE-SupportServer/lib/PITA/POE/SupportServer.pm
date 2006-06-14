package PITA::POE::SupportServer;

use strict;
use warnings;

use POE qw( Component::Server::HTTPServer Wheel::Run );
# import constants like H_FINAL
use POE::Component::Server::HTTPServer::Handler;

use Process;

use base qw( Process );

our $VERSION = '0.01';

# TODO use class accessor?

sub new {
    my $package = shift;

    # TODO error checking here?

    bless( { params => { @_ } }, $package );
}

sub prepare {
    my $self = shift;
    my %opt =  %{ delete $self->{params} };

    unless ( $opt{execute} && ref( $opt{execute} ) eq 'ARRAY' ) {
        $self->{errstr} = 'execute must be an array ref';
        return undef;
    }
    $self->{execute}               = delete $opt{xecute};
    
    unless ( $opt{http_mirrors} && ref( $opt{http_mirrors} ) eq 'HASH' ) {
        $self->{errstr} = 'http_mirrors must be a hash ref of image paths to local paths';
        return undef;
    }
    $self->{http_mirrors}          = delete $opt{http_mirrors};
    
    $self->{http_local_addr}       = delete $opt{http_local_addr} || '127.0.0.1';
    $self->{http_local_port}       = delete $opt{http_local_port} || 80;
    $self->{http_result}           = delete $opt{http_result} || '/result.xml';
    $self->{http_startup_timeout}  = delete $opt{http_startup_timeout} || 30;
    $self->{http_activity_timeout} = delete $opt{http_activity_timeout} || 3600;
    $self->{http_shutdown_timeout} = delete $opt{http_shutdown_timeout} || 10;

    if ( keys %opt ) {
        $self->{errstr} = 'unknown parameters: '.join( ',', keys %opt );
        return undef;
    }

    $self->{http_id} = POE::Session->create(
        object_states => [
            $self => [qw(
                _start
                signals
                http_request
            )],
        ]
    )->ID();
    
    1;
}

sub run {
    my $self = shift;

    # TODO setup timers

    $self->{_http_service} = $self->{_http_server}->create_server();

    $poe_kernel->run();

    $self->{errstr} ? undef : 1;
}

sub http_result {
    1;
}


# Private methods

sub _start {
    my ( $self, $kernel, $session ) = @_[ OBJECT, KERNEL, SESSION ];

    $kernel->sig( DIE => 'signals' );

    my $svr = $self->{_http_server} = POE::Component::Server::HTTPServer->new();

    # bah, HTTPServer doesn't have an address method, yet

    $svr->port( $self->{http_local_port} );

    $svr->handlers( [
        '/' => $session->postback( 'http_request' )
    ] );
}

sub signals {
    my $sig = $_[ARG0];

    if ( $sig eq 'DIE' ) {
        my ( $self, $event, $file, $line, $from_state, $error )
            = @_[ OBJECT, ARG2 .. ARG6 ];
    
        $self->{errstr} = "POE Exception at line $line in file "
            ."$file (state '$from_state' called '$event') Error: $error";
    }
}

sub http_request {
    my $context = shift;
    my $r = $context->{response};
#    my $s = $context->{request};
    
    $r->code( 200 );
    $r->content( "OK" );
    $r->content_type( 'text/html' );
    
    return H_FINAL;
}

1;

__END__

=head1 NAME

PITA::POE::SupportServer

=head1 SYNOPSIS

  use PITA::POE::SupportServer;

  my $server = PITA::POE::SupportServer->new(
          execute => [
                  '/usr/bin/qemu',
                  '-snapshot',
                  '-hda',
                  '/var/pita/image/ba312bb13f.img',
                  ],
          http_local_addr => '127.0.0.1',
          http_local_port => 80,
          http_mirrors => {
                  '/cpan' => '/var/cache/minicpan',
                  },
          http_result => '/result.xml',
          http_startup_timeout => 30,
          http_activity_timeout => 3600,
          http_shutdown_timeout => 10,
          ) or die "Failed to create support server";
  
  $server->prepare
          or die "Failed to prepare support server";
  
  $server->run
          or die "Failed to run support server";
  
  my $result_file = $server->http_result('/result.xml')
          or die "Guest Image execution failed";

=head1 ABSTRACT

=head1 DESCRIPTION

=head1 METHODS

=head2 EXPORT

Nothing.

=head1 AUTHORS

David Davis E<lt>xantus@cpan.orgE<gt>, Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<PITA>, L<POE>, L<Process>, L<http://ali.as/>

=head1 COPYRIGHT AND LICENSE

Copyright 2006 David Davis. All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

