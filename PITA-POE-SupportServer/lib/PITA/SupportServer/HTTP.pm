package PITA::SupportServer::HTTP;

# The HTTP server component of the support server

use 5.008;
use strict;
use warnings;
use POE::Declare::HTTP::Server ();

our $VERSION = '0.50';
our @ISA     = 'POE::Declare::HTTP::Server';





######################################################################
# Constructor or Accessor

sub new {
	my $self = shift->SUPER::new(
		Mirrors => { },
		@_,
		Handler => sub {
			# Convert to a more convention form
			$_[0]->handler( $_[1]->request, $_[1] );
		},
	);

	# Set up the file storage
	$self->{Files} = { };

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

# Register feedback messages
use POE::Declare {
	Mirrors    => 'Param',
	Files      => 'Attribute',
	PingEvent  => 'Message',
	FileEvent  => 'Message',
	GuestEvent => 'Message',
};





######################################################################
# Main Methods

sub run {
	$_[0]->start;
	POE::Kernel->run;
	return 1;
}

sub handler {
	my $self     = shift;
	my $request  = shift;
	my $response = shift;

	if ( $request->method eq 'GET' ) {
		# Handle a ping
		if ( $request->uri eq '/' ) {
			$self->PingEvent;
			$response->code( 200 );
			$response->content('PONG');
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
				$response->header( 'Content-Length' => length $blob         );
				$response->content( $blob );
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
		$self->{Files}->{$path} = $blob;

		# Send an ok to the client
		$response->code(200);
		$response->header( 'Content-Type' => 'text/plain' );
		$response->content( "$path OK" );
		return;
	}

	return;
}

compile;
