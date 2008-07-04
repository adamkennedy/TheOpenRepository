package HTTP::Client::Parallel;

=pod

=head1 NAME

HTTP::Client::Parallel - A HTTP client that fetchs all URIs in parallel

=head1 SYNOPSIS

  # Create the parallising client
  my $client = HTTP::Client::Parallel->new;
  
  # Simple fetching
  my $pages = $client->get(
    'http://www.google.com/',
    'http://www.yapc.org/',
    'http://www.yahoo.com/',
  );
  
  # Mirroring to disk
  my $responses = $client->mirror(
    'http://www.google.com/' => 'mirrors/google.html',
    'http://www.yapc.org/'   => 'mirrors/yapc.html',
    'http://www.yahoo.com/'  => 'mirrors/yahoo.html',
  );

=head1 DESCRIPTION

Fetching a URI is a very common network-bound task in many types of
programming. Fetching more than one URI is also very common, but unless
the fetches are capable of entirely saturating a connection, typically
time is wasted because there is often no logical reason why multiple
requests cannot be made in parallel.

Executing IO-bound and network-bound tasks is extremely easy in any
event-based programming model such as L<POE>, but these event-based
systems normally require complete control of the application and
that the program be written in a very different way.

Thus, the biggest problem preventing running HTTP requests in
parallel is not that it isn't possible, but that mixing procedural
and event programming is difficult.

The few existing mechanisms generally rely on forking or other
platform-specific methods.

B<HTTP::Client::Parallel> is designed to bridge the gap between
typical cross-platform procedural code and typical cross-platform
event-based code.

It allows you to set up a series of HTTP tasks (fetching to memory,
fetching to disk, and mirroring to disk) and then issue a single
method call which will block and execute all of them in parallel.

Behind the scenes HTTP::Client::Parallel will B<temporarily> hand
over control of the process to L<POE> to execute the HTTP tasks.

Once all of the HTTP tasks are completed (using the standard
L<POE::Component::HTTP::Client> module, the POE kernel will shut
down and hand control of the application back to the normal
procedural code, and thus back to your code.

As a result, a developer with no knowledge of L<POE> or event-based
programming can still take advantage of the capabilities of POE and
gain major speed increases in HTTP-based programs with relatively
little work.

=cut

use 5.006;
use strict;
use warnings;
use Exporter     'import';
use Scalar::Util 'blessed';
use Params::Util '_INSTANCE';
use IO::File;
use HTTP::Request;
use POE qw{
    Component::Client::HTTP
};

use vars qw{ $VERSION @EXPORT_OK };
BEGIN {
    $VERSION   = '0.01';
    @EXPORT_OK = qw{ mirror getstore get }
}

use constant HCP => 'HTTP::Client::Parallel';





#####################################################################
# Constructor

sub new {
    my $class = shift;
    my %args  = @_;

    # Create the client object
    my $self  = bless {
        requests  => {}, 
        results   => {},
        count     => 0,
    }, $class;

    $self->{sid} = POE::Session->create(
        object_states => [
            $self => {
                _start    => '_start',
                _stop     => '_stop',
                aggregate => 'aggregate',
                execute   => '_execute',
            },
         ]
    )->ID;

    return $self;
}

# Non POE
sub fetch {
    POE::Kernel->run;
}

sub get {
    my $self = _INSTANCE($_[0], HCP) ? shift : HCP->new;
    foreach ( @_ ) {
        $self->queue( uri => $_ );
        $self->fetch;
    }
    return $self->{results};
}

sub mirror {
    my $self = _INSTANCE($_[0], HCP) ? shift : HCP->new;
    my %args = @_;

    #if (-e $file) {
        #my ($mtime) = (stat($file))[9];
        #if( $mtime ) {
            #$request->header('If-Modified-Since' =>
                    #HTTP::Date::time2str($mtime));
        #}
    #}

    #my $tmpfile = "$file-$$";
}

sub getstore {
    my $self = _INSTANCE($_[0], HCP) ? shift : HCP->new;
    my %args = @_;
    foreach ( keys %args ) {
        $self->queue( uri => $_ );
    }
    $self->fetch;

    my $results = {};
    foreach my $result ( keys %{$self->{results}} ) {
        next unless $args{$result};
        my $response = $self->{results}->{$result}->{response};
        $results->{$result} = $response->code;
        if( $response->is_success and my $file = IO::File->new( $args{$result}, 'w') ) {
            print $file $response->content;
            $file->close;

        } else {
            warn "Could not save file: $args{$result} for uri: $result because: $!\n";

        }
    }

    return $results;
}

sub queue {
    my $self = shift;
    my %args = @_;
    return unless $args{uri};

    if ( _INSTANCE($args{uri}, 'HTTP::Request') ) {
        $self->{requests}->{$args{uri}->as_string} = $args{uri};
        $self->{count}++;

    } elsif ( _INSTANCE($args{uri}, 'URI') or ! ref $args{uri} ) {
        $self->{requests}->{"$args{uri}"} = HTTP::Request->new( GET => $args{uri} );
        $self->{count}++;
    }

    return 1;
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
    my $self  = $_[OBJECT];
    my $class = ref $self;

    POE::Component::Client::HTTP->spawn(
        Agent     => "$class/$VERSION",
        Alias     => "ua$self",               # defaults to 'weeble'
        # From      => 'spiffster@perl.org',  # defaults to undef (no header)
        # Protocol  => 'HTTP/0.9',            # defaults to 'HTTP/1.1'
        # Timeout   => 60,                    # defaults to 180 seconds
        # MaxSize   => 16384,                 # defaults to entire response
        # Streaming => 4096,                  # defaults to 0 (off)
        FollowRedirects => 2                  # defaults to 0 (off)
        # Proxy     => "http://localhost:80", # defaults to HTTP_PROXY env. variable
        # BindAddr  => "12.34.56.78",         # defaults to INADDR_ANY
    );
    
    foreach ( keys %{$self->{requests}} ) {
        POE::Kernel->post(
            "ua$self",               # posts to the 'ua' alias
            'request',               # posts to ua's 'request' state
            'aggregate',             # which of our states will receive the response
            $self->{requests}->{$_}, # an HTTP::Request object
        );
    }
}

sub aggregate {
    my $self = $_[OBJECT];
    my ($request_packet, $response_packet) = @_[ARG0, ARG1];
    $self->{count}--;

    # HTTP::Request
    my $request_object  = $request_packet->[0];

    # HTTP::Response
    my $response_object = $response_packet->[0];

    my $string;
    foreach my $uri_string ( keys %{$self->{requests}} ) {
        if ( "$self->{requests}->{$uri_string}" eq "$request_object" ) {
            $self->{results}->{$uri_string} = {
                original_req => $request_object, 
                response     => $response_object,
            };
        }
    }

    POE::Kernel->call( "ua$self" => 'shutdown' ) unless $self->{count};
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTTP-Client-Parallel>

For other issues, contact the author.

=head1 AUTHOR

Marlon Bailey E<lt>mbaily@cpan.orgE<gt>

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<LWP::Simple>, L<POE>

=head1 COPYRIGHT

Copyright 2008 Marlon Bailey and Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
