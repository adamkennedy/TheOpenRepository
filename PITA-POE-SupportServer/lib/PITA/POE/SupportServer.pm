package PITA::POE::SupportServer;

use strict;
use warnings;
use Params::Util qw( _ARRAY _HASH );

use POE qw( Component::Server::HTTPServer Filter::Line Wheel::Run );
# import constants like H_FINAL
use POE::Component::Server::HTTPServer::Handler;

use Process;
use base qw( Process );

our $VERSION = '0.01';

sub new {
    my $package = shift;

    # TODO error checking here?

    bless( { params => { @_ } }, $package );
}

sub prepare {
    my $self = shift;
    my %opt =  %{ delete $self->{params} };

    unless ( _ARRAY($opt{execute}) ) {
        $self->{errstr} = 'execute must be an array ref';
        return undef;
    }
    $self->{execute}               = delete $opt{execute};
    
    unless ( _HASH($opt{http_mirrors}) ) {
        $self->{errstr} = 'http_mirrors must be a hash ref of image paths to local paths';
        return undef;
    }
    $self->{http_mirrors}          = delete $opt{http_mirrors};
    $self->{http_local_addr}       = delete $opt{http_local_addr} || '127.0.0.1';
    $self->{http_local_port}       = delete $opt{http_local_port} || 80;
    $self->{http_result}           = delete $opt{http_result} || [ '/result.xml' ];
    unless ( _ARRAY( $self->{http_result} ) ) {
        $self->{http_result} = [ $self->{http_result} ];
    }
    $self->{http_startup_timeout}  = delete $opt{http_startup_timeout} || 30;
    $self->{http_activity_timeout} = delete $opt{http_activity_timeout} || 3600;
    $self->{http_shutdown_timeout} = delete $opt{http_shutdown_timeout} || 10;

    if ( keys %opt ) {
        $self->{errstr} = 'unknown parameters: '.join( ',', keys %opt );
        return undef;
    }

    $self->{_session_id} = POE::Session->create(
        object_states => [
            $self => [qw(
                _start
                signals
                http_request
                http_result
                execute
                shutdown
                
                error
                closed
                stdin
                stderr
                stdout

                startup_timeout
                activity_timeout
                shutdown_timeout
            )],
        ]
    )->ID();
 
    $self->{_has_run} = 0;
 
    1;
}

sub run {
    my $self = shift;

    # TODO setup timers
    
    unless( $self->{_session_id} ) {
        $self->{errstr} = "You must prepare() before run()";
        return undef;
    }
    
    $self->{_has_run}++;

    $self->{_http_service} = $self->{_http_server}->create_server();

    $poe_kernel->post( $self->{_session_id} => 'execute' );

    $poe_kernel->run();

    # cleanup
    delete @{$self}->{qw( _http_service _http_server _wheel _session_id )};

    $self->{errstr} ? undef : 1;
}

sub http_result {
    shift->{_http_result} || undef;
}

sub has_run {
    shift->{_has_run} || 0;
}

# Private methods and events

sub _start {
    my ( $self, $kernel, $session ) = @_[ OBJECT, KERNEL, SESSION ];

    $kernel->sig( DIE => 'signals' );

    my $svr = $self->{_http_server} = POE::Component::Server::HTTPServer->new();

    # bah, HTTPServer doesn't have an address method, yet

    $svr->port( $self->{http_local_port} );

    # XXX we may not need to setup handlers for each http_result
    $svr->handlers( [
        '/' => $session->postback( 'http_request' ),
        ( map { $_ => $session->postback( 'http_result', $_ ) } @{$self->{http_result}} ),
    ] );
}

sub signals {
    my $sig = $_[ ARG0 ];

    if ( $sig eq 'DIE' ) {
        my ( $kernel, $self, $event, $file, $line, $from_state, $error )
            = @_[ KERNEL, OBJECT, ARG2 .. ARG6 ];
    
        $self->{errstr} = "POE Exception at line $line in file $file "
            ." (state '$from_state' called '$event') Error: $error";

        $kernel->sig_handled();

        $kernel->call( $_[ SESSION ] => 'shutdown' );
    }
}

sub http_request {
    my $context = shift;
    my $r = $context->{response};
#    my $s = $context->{request};
    
    require Data::Dumper;
    warn Data::Dumper->Dump( [ $r ] );

    # XXX 
    # if startup request, then kill startup timeout
    # if activity request, then reset activity timeout

    $r->code( 200 );
    $r->content( "OK" );
    $r->content_type( 'text/html' );
    
    return H_FINAL;
}

sub http_result {
    # TODO check if this is right for a postback
    my ( $self, $result, $context ) = ( $_[ OBJECT ], $_[ ARG0 ]->[ 0 ], $_[ ARG1 ]->[ 0 ] );
    my $r = $context->{response};
#    my $s = $context->{request};
    
    require Data::Dumper;
    warn Data::Dumper->Dump( [ $r ] );

    # XXX 
    # if activity request, then reset activity timeout

    $r->code( 200 );
    $r->content( "OK" );
    $r->content_type( 'text/html' );
    
    return H_FINAL;
}

sub execute {
    my ( $self, $kernel ) = @_[ OBJECT, KERNEL ];

    my @args = @{$self->{execute}};
   
    $self->{_http_startup_timer} = $kernel->alarm_set( startup_timeout => $self->{http_startup_timeout} );
 #   $self->{_http_activity_timer} = $kernel->alarm_set( activity_timeout => $self->{http_activity_timeout} );
   
    $self->{_wheel} = POE::Wheel::Run(
        Program      => shift @args,
        ProgramArgs  => \@args,
        StderrFilter => POE::Filter::Line->new(),
        StdioFilter  => POE::Filter::Line->new(),
        ErrorEvent   => 'error',
        CloseEvent   => 'closed',
        StdinEvent   => 'stdin',
        StdoutEvent  => 'stdout',
        StderrEvent  => 'stderr',
    );
}

sub shutdown {
    my ( $self, $kernel ) = @_[ OBJECT, KERNEL ];
    
    # XXX is this right?
    $self->{_http_shutdown_timer} = $kernel->alarm_set( shutdown_timeout => $self->{http_shutdown_timeout} );
    
    $self->{_wheel}->kill() if ( $self->{_wheel} );
    
    # TODO set timer and recheck for wheel closure
    
    delete @{$self}->{qw( _http_service _http_server )};
}

sub error {
    my ( $kernel, $self, $ret, $errno, $error, $wheel_id, $handle ) = @_[ KERNEL, OBJECT, ARG0 .. ARG5 ];
    
    $self->{errstr} = "Error no $errno on $handle : $error ( Return value: $ret )";

    $kernel->call( $_[ SESSION ] => 'shutdown' );
}

sub closed {
    my ( $self, $kernel ) = @_[ OBJECT, KERNEL];
    
    $self->{_wheel_closed}++;
    
    $kernel->call( $_[ SESSION ] => 'shutdown' );
}

sub stdin {
    warn $_[ARG0];
}

sub stdout {
    warn $_[ARG0];
}

sub stderr {
    warn $_[ARG0];
}

sub startup_timeout {
    warn "startup_timeout";
}

sub activity_timeout {
    warn "activity_timeout";
}

sub shutdown_timeout {
    warn "shutdown_timeout";
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

