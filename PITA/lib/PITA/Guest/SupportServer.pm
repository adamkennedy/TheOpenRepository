package PITA::Guest::SupportServer;

=pod

=head1 NAME

PITA::Guest::SupportServer - Provides support services via HTTP for Guest images.

=head1 DESCRIPTION

Because each testing image is a black box with potentially different and
unusual properties, a consistent method is needed to pull in any additional
files needed by the image (such as CPAN distributions) and get the result
reports out of the image and return them to the PITA Host.

One common capability all testing images have is the ability to connect
out to the Host machine over the network. Because of this, we can provide
whatever services are necesary for the installation by creating a custom
HTTP server that accepts and proxies GET requests for CPAN files, and
accepts results via specially-formed PUT requests.

This class implements such a web server.

I<Note: At the present time, only the PUT half of the functionality has
actually been completed>

=head1 METHODS

=cut

use strict;
use base 'Process::Backgroundable', 'Process';
use Carp           ();
use File::Spec     ();
use File::Flock    ();
use File::Remove   ();
use Params::Util   '_POSINT';
use URI            ();
use HTTP::Daemon   ();
use HTTP::Status   ();
use HTTP::Request  ();
use HTTP::Response ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.22';
}





#####################################################################
# Constructor and Accessors

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Check the params
	unless ( $self->{LocalAddr} ) {
		Carp::croak("SupportServer 'LocalAddr' was not provided");
	}
	unless ( $self->{LocalPort} ) {
		Carp::croak("SupportServer 'LocalPort' was not provided");
	}
	unless ( _POSINT($self->{LocalPort}) ) {
		Carp::croak("SupportServer 'LocalPort' was invalid");
	}
	unless ( $self->{directory} ) {
		Carp::croak("SupportServer 'directory' for saving not provided");
	}

	# Internally, make the expected a list
	if ( defined $self->{expected} ) {
		unless ( _POSINT($self->{expected}) ) {
			Carp::croak("SupportServer 'expected' not a posint id");
		}
	}
	$self->{expected} = $self->{expected} ? [ $self->{expected} ] : [];

	# Set the base access url
	$self->{uri} = URI->new(
		"http://" . $self->LocalAddr . ':' . $self->LocalPort . '/'
		);

	$self;
}

sub LocalAddr {
	$_[0]->{LocalAddr};
}

sub LocalPort {
	$_[0]->{LocalPort};
}

sub expected {
	@{$_[0]->{expected}};
}

sub directory {
	$_[0]->{directory};
}

sub daemon {
	$_[0]->{daemon};
}

sub uri {
	$_[0]->{uri};
}

sub pidfile {
	$_[0]->{pidfile};
}

sub stop {
	my $self = shift;

	# Delete the PID lock, and manually remove the file if needed
	if ( $self->pidfile and -f $self->pidfile ) {
		File::Remove::remove($self->pidfile);
		delete $self->{pidfile};
	}

	# If we aren't running, clear the daemon too
	if ( ! $self->{run} and $self->daemon ) {
		undef $self->{daemon};
		delete $self->{daemon};
	}

	1;
}





#####################################################################
# Main Methods

# Add a report id to the expected list
sub expect {
	my $self   = shift;
	my $report = _POSINT(shift)
		or Carp::croak("Did not pass a posint Report id");
	push @{$self->{expected}}, $report;
	1;
}

# Prepare and bind resources
sub prepare {
	my $self = shift;
	return 1 if $self->{prepared};
	$self->{prepared} = 1;

	# Does the support-server directory exist
	unless ( -d $self->{directory} and -w _ ) {
		return undef;
		# Carp::croak("SupportServer 'directory' is not a writable directory");
	}

	# Create the daemon
	$self->{daemon} = HTTP::Daemon->new(
		LocalAddr => $self->LocalAddr,
		LocalPort => $self->LocalPort,
		ReuseAddr => 1,
		);
	unless ( $self->daemon ) {
		#return undef;
		Carp::croak("Failed to create daemon object: $@");
	}
	$self->daemon->timeout(1);

	# Create the PID file
	$self->{pidfile} = File::Spec->catfile(
		$self->directory, "$$.pid",
		);
	open( PID, '>', $self->{pidfile} ) or return undef;
	print PID $self->uri . "\n"        or return undef;
	close PID                          or return undef;

	1;
}

sub run {
	my $self = shift;
	return 1 if $self->{run};
	$self->{run} = 1;

	# Set the SIGTERM shutdown hook
	my $daemon = $self->daemon;
	local $SIG{TERM} = sub { $self->stop };

	# Wait for connections
	while ( -f $self->pidfile ) {
		my $c = $daemon->accept or next;
		my $r = $c->get_request;
		if ( $r ) {
			eval { $self->_request( $r, $c ) };
			$c->send_error(
				HTTP::Status::RC_INTERNAL_SERVER_ERROR(),
				"$@" ) if $@;

			# Stop if we aren't expecting anything
			$self->stop unless $self->expected;

		} else {
			$c->send_error(
				HTTP::Status::RC_INTERNAL_SERVER_ERROR()
				);
		}
		$c->force_last_request;
		$c->close;
		undef($c);
	}

	# Clean up our resources
	undef $self->{daemon};

	1;
}

# There is a problem where sometimes you can be firing requests
# at it before it is ready.
# So always pause for a second to let the server prepare to take requests.
sub background {
	my $self = shift;
	$self->SUPER::background(@_);
	sleep 1;
	return 1;
}






#####################################################################
# Mirrored functions from the parent side

sub parent_pid {
	my $self = shift;

	# Get the contents of the working directory
	opendir( TESTDIR, $self->directory )
		or die "Failed to open working directory";
	my @files = readdir( TESTDIR );
	closedir( TESTDIR );

	# Filter to find the pidfile
	@files = map { /(\d+)\.pid$/ ? $1 : () }
		File::Spec->no_upwards( @files );
	return '' unless @files; # No PID file exists

	# A weirder case would be to find more than one
	if ( @files > 1 ) {
		die "Found more than one PID file";
	}

	$files[0];
}

sub parent_pidfile {
	my $self    = shift;
	my $pid     = $self->parent_pid or return '';
	my $pidfile = File::Spec->catfile( $self->directory, $pid . ".pid" );
	-f $pidfile ? $pidfile : '';
}





#####################################################################
# Support Methods

sub _request {
	my ($self, $r, $c) = @_;

	# Send to the appropriate handlers
	if ( $r->method eq 'GET' ) {
		return $self->_request_get( $r, $c );
	}
	if ( $r->method eq 'PUT' ) {
		return $self->_request_put( $r, $c );
	}

	# Unsupported method
	return $c->send_error(
		HTTP::Status::RC_METHOD_NOT_ALLOWED(),
		'Only GET and PUT supported on this server',
		);
}

sub _request_get {
	my ($self, $r, $c) = @_;

	# Create our response
	my $say      = ref($self) . ' ' . $VERSION . "\n";
	my $response = HTTP::Response->new( 200 => 'Pong', [
		'Content-Type'   => 'text/html',
		'Content-Length' => length($say),
		], $say );
	unless ( $response ) {
		# Failed to create the response, wtf?
		return $c->send_error(
			HTTP::Status::RC_INTERNAL_SERVER_ERROR()
			);
	}

	# Send the response
	$c->send_response( $response );
}

sub _request_put {
	my ($self, $r, $c) = @_;

	# The path should be /$expected
	my $uri  = $r->uri;
	my $path = $uri->path;
	$path =~ s{^/}{}; # Remove leading slash
	unless ( _POSINT($path) ) {
		return $c->send_error(
			HTTP::Status::RC_NOT_FOUND(),
			'Request path is not a PITA request identifier',
			);
	}

	# Are we expecting this
	my $expected = $self->{expected};
	unless ( grep { $path eq $_ } @$expected ) {
		return $c->send_error(
			HTTP::Status::RC_NOT_FOUND(),
			'Not expecting that PITA request identifier',
			);
	}

	# The mime-type should be application/xml
	unless ( $r->header('content_type') eq 'application/xml' ) {
		return $c->send_error(
			HTTP::Status::RC_UNSUPPORTED_MEDIA_TYPE(),
			'Content-Type must be application/xml',
			);
	}

	# Get the XML data and save
	my $file = File::Spec->catfile(
		$self->directory, "$path.pita"
		);
	unless (
	open( XML, '>', $file) and
	print XML $r->content   and
	close( XML )
	) {
		return $c->send_error(
			HTTP::Status::RC_INTERNAL_SERVER_ERROR,
			'Failed to write PITA Report to disk',
			);
	}

	# Thank them for the upload
	$c->send_basic_header( 200, 'Report recieved and saved ok' );

	# Clear the entry from the expected array
	@$expected = grep { $_ ne $path } @$expected;

	1;
}

# Clear out the pid file in some more extreme situations.
# Everything short of a full SIGKILL should be ok.
sub DESTROY {
	if ( $_[0]->{pidfile} and -f $_[0]->{pidfile} ) {
		File::Remove::remove($_[0]->{pidfile});
	}
}

1;

__END__

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=PITA>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy, L<http://ali.as/>, cpan@ali.as

=head1 COPYRIGHT

Copyright 2005, 2006 Adam Kennedy. All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
