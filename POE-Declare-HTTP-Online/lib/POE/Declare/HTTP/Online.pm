package POE::Declare::HTTP::Online;

=pod

=head1 NAME

POE::Declare::HTTP::Online - Does your POE process have access to the web

=head1 SYNOPSIS

    my $online = POE::Declare::HTTP::Online->new(
        Timeout      => 10,
        OnlineEvent  => \&handle_online,
        OfflineEvent => \&handle_offline,
        ErrorEvent   => \&handle_unknown,
    );
    
    $online->run;

=head1 DESCRIPTION

This is a port of L<LWP::Online> to L<POE::Declare>. It behaves similarly to
the original, except that it does not depend on LWP and can execute the HTTP
probes in parallel.

=cut

use 5.008;
use strict;
use Carp                            ();
use Params::Util               1.00 ();
use POE::Declare::HTTP::Client 0.04 ();

our $VERSION = '0.01';

use POE::Declare 0.54 {
	Timeout      => 'Param',
	Tests        => 'Param',
	OnlineEvent  => 'Message',
	OfflineEvent => 'Message',
	ErrorEvent   => 'Message',
	client       => 'Internal',
	result       => 'Internal',
};

my %DEFAULT = (
	# These are some initial trivial checks.
	# The regex are case-sensitive to at least
	# deal with the "couldn't get site.com case".
	'http://google.com'     => sub { /About Google/                },
	'http://yahoo.com/'     => sub { /Yahoo!/                      },
	'http://cnn.com/'       => sub { /CNN/                         },
	'http://microsoft.com/' => sub { /&#169;(\s+\d+)?\s+Microsoft/ },

	# Generates warnings with HTTP::Parser 0.06
	# 'http://amazon.com/' => sub { /Amazon/ and /Cart/ },
);





######################################################################
# Constructor and Accessors

=pod

=head2 new

    my $online = POE::Declare::HTTP::Online->new(
        Timeout      => 10,
        OnlineEvent  => \&handle_online,
        OfflineEvent => \&handle_offline,
        ErrorEvent   => \&handle_unknown,
    );

The C<new> constructor sets up a reusable HTTP online status checker that can
be run as often as needed.

Unless actively in use, the online detection object will not consume a L<POE>
session.

=cut

sub new {
	my $self = shift->SUPER::new(@_);

	unless ( defined $self->Timeout ) {
		$self->{Timeout} = 10;
	}
	unless ( defined $self->Tests ) {
		$self->{Tests} = \%DEFAULT;
	}
	unless ( Params::Util::_HASH($self->Tests) ) {
		Carp::croak("Missing or invalid 'Test' param");
	}

	# Pre-generate a client for each request
	$self->{client} = { };
	foreach my $url ( $self->urls ) {
		$self->{client}->{$url} = POE::Declare::HTTP::Client->new(
			Timeout       => $self->Timeout - 1,
			ResponseEvent => $self->lookback('http_response'),
			ShutdownEvent => $self->lookback('http_shutdown'),
		);
	}

	return $self;
}

sub urls {
	keys %{ $_[0]->Tests };
}

sub clients {
	map { $_[0]->{client}->{$_} } $_[0]->urls
}





######################################################################
# Methods

=pod

=head2 run

The C<run> method starts the online detection process, spawning the L<POE>
session and initiating HTTP Test to each of the test URLs in parallel.

Once a determination has been made as to our online state (positive, negative
or unknown) and the reporting event has been fired, the session will be
terminated immediately.

=cut

sub run {
	my $self = shift;
	unless ( $self->spawned ) {
		$self->spawn;
	}
	return 1;
}





######################################################################
# Event Handlers

sub _start :Event {
	$_[SELF]->SUPER::_start(@_[1..$#_]);

	# Initialise state variables and boot the HTTP clients
	$_[SELF]->{result} = {
		online  => 0,
		offline => 0,
		unknown => 0,
	};
	foreach my $url ( $_[SELF]->urls ) {
		$_[SELF]->{client}->{$url}->start;
	}

	$_[SELF]->post('startup');
}

sub startup :Event {
	$_[SELF]->timeout_start($_[SELF]->Timeout);
	foreach my $url ( $_[SELF]->urls ) {
		$_[SELF]->{client}->{$url}->GET($url);
	}
}

# We're so slow that we should assume we're not online
sub timeout :Timeout(10) {
	$_[SELF]->call( respond => 0 );
}

sub http_response :Event {
	my $alias    = $_[ARG0];
	my $response = $_[ARG1];
	my $result   = $_[SELF]->{result};

	# Check that we have a valid response
	unless ( Params::Util::_INSTANCE($response, 'HTTP::Response') ) {
		return $_[SELF]->call( respond => undef );
	}

	# Find the original request URL
	foreach my $url ( $_[SELF]->urls ) {
		my $client = $_[SELF]->{client}->{$url};
		next unless $client->Alias eq $alias;

		# Got the response for this URL
		if ( $response->is_success ) {
			local $_ = $response->content;
			if ( $_[SELF]->Tests->{$url}->() ) {
				$result->{online}++;
			} else {
				$result->{offline}++;
			}
		} else {
			$result->{offline}++;
		}

		# Are we online?
		if ( $result->{online} >= 2 ) {
			return $_[SELF]->call( respond => 1 );
		}

		# Are there any active clients left
		if ( grep { $_->running } $_[SELF]->clients ) {
			# No definite answer yet
			return;
		}

		# We are not online, so far as we can tell
		return $_[SELF]->call( respond => 0 );
	}

	# Are there any active clients left
	if ( grep { $_->running } $_[SELF]->clients ) {
		# No definite answer yet
		return;
	}

	# We are not online, so far as we can tell
	return $_[SELF]->call( respond => 0 );
}

sub http_shutdown :Event {
	print STDERR "# http_response $_[ARG0]\n";
}

sub respond :Event {
	$_[SELF]->{result} = undef;

	# Abort any requests still running
	foreach my $url ( $_[SELF]->urls ) {
		$_[SELF]->{client}->{$url}->stop;
	}

	# Send the reponse message
	if ( $_[ARG0] ) {
		$_[SELF]->OnlineEvent;
	} elsif ( defined $_[ARG0] ) {
		$_[SELF]->OfflineEvent;
	} else {
		$_[SELF]->ErrorEvent;
	}

	# Clean up
	$_[SELF]->finish;
}

compile;

=pod

=head1 SUPPORT

Bugs should be always be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=POE-Declare-HTTP-Online>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<LWP::Simple>

=head1 COPYRIGHT

Copyright 2011 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
