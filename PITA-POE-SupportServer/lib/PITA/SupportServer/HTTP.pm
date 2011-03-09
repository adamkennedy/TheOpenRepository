package PITA::SupportServer::HTTP;

# The HTTP server component of the support server

use 5.008;
use strict;
use warnings;
use POE::Declare::HTTP::Server ();

our $VERSION = '0.50';
our @ISA     = 'POE::Declare::HTTP::Server';

use POE::Declare {
	Mirrors     => 'Param',
	PingEvent   => 'Message',
	MirrorEvent => 'Message',
	UploadEvent => 'Message',
};





######################################################################
# Constructor and Accessors

sub new {
	my $self = shift->SUPER::new(
		Mirrors => { },
		@_,
		Handler => sub {
			# Convert to a more convention form
			$_[0]->handler( $_[1]->request, $_[1] );
		},
	);

	# Check params
	unless ( Params::Util::_HASH0($self->Mirrors) ) {
		die "Missing or invalid Mirrors param";
	}
	foreach my $route ( sort keys %{$self->Mirrors} ) {
		unless ( -d $self->Mirrors->{$route} ) {
			die "Directory for mirror '$route' does not exist";
		}
	}

	return $self;
}





######################################################################
# Main Methods

# Sort of half-assed Process compatibility for testing purposes
sub run {
	$_[0]->start;
	POE::Kernel->run;
	return 1;
}

# Wrapper for doing cleansing of the response
sub handler {
	my $self     = shift;
	my $response = $_[1];

	# Call the main handler
	$self->_handler(@_);

	# Add content length for all responses
	if ( defined $response->content ) {
		unless ( $response->header('Content-Length') ) {
			my $bytes = length $response->content;
			$response->header( 'Content-Length' => $bytes );
		}
	}

	return;
}

sub _handler {
	my $self     = shift;
	my $request  = shift;
	my $response = shift;

	if ( $request->method eq 'GET' ) {
		# Handle a ping
		if ( $request->uri->path eq '/' ) {
			$response->code(200);
			$response->content('PONG');
			$self->PingEvent;
			return;
		}

		# Handle a mirror file fetch
		foreach my $route ( sort keys %{$self->Mirrors} ) {
			my $escaped = quotemeta $route;
			next unless $request->uri =~ /^$escaped(.+)$/;
			my $path = $1;
			my $root = $self->Mirrors->{$route};
			my $file = File::Spec->catfile( $root, $path );
			if ( -f $file and -r $file ) {
				# Load the file
				local $/ = undef;
				my $io = IO::File->new($file, 'r') or die "open: $file";
				$io->binmode;
				my $blob = $io->getline;

				# Send the file
				$response->code(200);
				$response->header( 'Content-Type'   => 'application/x-gzip' );
				$response->content( $blob );

				$self->MirrorEvent( $route, $path );
				return;
			} else {
				$response->code(404);
				$response->header( 'Content-Type' => 'text/plain' );
				$response->content('404 - File Not Found');
				return;
			}
		}
	}

	if ( $request->method eq 'PUT' ) {
		# Save the uploaded content
		my $path = $request->uri->as_string;
		my $blob = \( $request->content );

		# Send an ok to the client
		$response->code(204);
		$response->message("Upload received");

		# Send the upload message
		$self->UploadEvent( $path, $blob );
		return;
	}

	return;
}

compile;
