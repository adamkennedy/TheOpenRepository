package HTTP::Client::Parallel;

use 5.006;
use strict;
use warnings;
use POE qw{Component::Client::HTTP);
use HTTP::Request;
use Scalar::Util qw(blessed);
use IO::File;
use Exporter 'import';

our @EXPORT_OK;
@EXPORT_OK = qw(mirror get);

sub new {
    my $class = shift;

    my %args = @_;

    my $self = { requests  => {}, 
                 results   => {},
                 count     => 0,
                };

    bless $self, $class;

    $self->{sid} = POE::Session->create(
                        object_states => [
                            $self => {
                                _start => '_start',
                                _stop  => '_stop',
                                aggregate_responses  => 'aggregate_responses',
                                execute  => '_execute',
                            }
                        ]
                   )->ID;

    return $self;
}

# Non POE
sub fetch {
    my $self = shift;
    POE::Kernel->run();
}

sub get {
    my $self;
    
    if( blessed($_[0]) and $_[0]->isa('HTTP::Client::Parallel') ) {
        $self = shift;
    }
    else {
        $self = __PACKAGE__->new();
    }

    $self->queue( uri => $_ ) for (@_);
    $self->fetch;

    return $self->{results};
}

sub mirror {
    my $self; 

    if( blessed($_[0]) and $_[0]->isa('HTTP::Client::Parallel') ) {
        $self = shift;
    }
    else {
        $self = __PACKAGE__->new();
    }

    my %args = @_;

    $self->queue( uri => $_ ) for (keys %args);
    $self->fetch;

    my $results = {};

    for my $result (keys %{$self->{results}}) {

        next unless $args{$result};

        if( my $file = IO::File->new( $args{$result}, 'w') ) {

            my $response = $self->{results}
                                ->{$result}
                                ->{response};

            $results->{$result} = $response->code;
            print $file $response->content;
            $file->close;
        }
        else {
            warn "Could not save file: $args{$result} for uri: $result because: $!\n";
        }
    }

    return $results;
}

sub queue {
    my $self = shift;
    my %args = @_;

    return 
        unless $args{uri};

    if( blessed $args{uri} and $args{uri}->isa('HTTP::Request') ) {

        $self->{requests}->{ $args{uri}->as_string } = $args{uri};
        $self->{count}++;
    }
    elsif( (blessed $args{uri} and $args{uri}->isa('URI')) or !(ref $args{uri})) {

        $self->{requests}->{ "$args{uri}" } =  HTTP::Request->new(GET => $args{uri});
        $self->{count}++;
    }
}

# POE 
sub _start {
    my $self = $_[OBJECT];

    POE::Kernel->alias_set("$self");
    POE::Kernel->yield('execute');
}

sub _stop {
    my $self = $_[OBJECT];
}

sub _execute {
    my $self = $_[OBJECT];

    POE::Component::Client::HTTP->spawn(
        Agent     => 'SpiffCrawler/0.90',   # defaults to something long
        Alias     => 'ua' . $self,                  # defaults to 'weeble'
        #From      => 'spiffster@perl.org',  # defaults to undef (no header)
        #Protocol  => 'HTTP/0.9',            # defaults to 'HTTP/1.1'
        #Timeout   => 60,                    # defaults to 180 seconds
        #MaxSize   => 16384,                 # defaults to entire response
        #Streaming => 4096,                  # defaults to 0 (off)
        FollowRedirects => 2                # defaults to 0 (off)
        #Proxy     => "http://localhost:80", # defaults to HTTP_PROXY env. variable
        #NoProxy   => [ "localhost", "127.0.0.1" ], # defs to NO_PROXY env. variable
        #BindAddr  => "12.34.56.78",         # defaults to INADDR_ANY
    );
    
    for (keys %{$self->{requests}} ) {

        POE::Kernel->post(
            'ua' . $self,     # posts to the 'ua' alias
            'request',   # posts to ua's 'request' state
            'aggregate_responses',  # which of our states will receive the response
            $self->{requests}->{$_},    # an HTTP::Request object
        );
    }
}

sub aggregate_responses {
    my $self = $_[OBJECT];
    my ($request_packet, $response_packet) = @_[ARG0, ARG1];

    $self->{count}--;
    # HTTP::Request
    my $request_object  = $request_packet->[0];

    # HTTP::Response
    my $response_object = $response_packet->[0];

    my $string;

    for my $uri_string (keys %{$self->{requests}}) {

        if("$self->{requests}->{$uri_string}" eq "$request_object") {

            $self->{results}->{$uri_string} = { original_req => $request_object, 
                                                response     => $response_object,
                                              };
        }
    }

    POE::Kernel->call( "ua$self" => 'shutdown')
        unless( $self->{count} );
}

1;
