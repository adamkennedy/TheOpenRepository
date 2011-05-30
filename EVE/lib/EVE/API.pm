package EVE::API;

use 5.008;
use strict;
use warnings;
use LWP::UserAgent ();

our $VERSION = '0.01';

sub post {
	my $class    = shift;
	my $path     = "http://api.eve-online.com" . shift;
	my $agent    = LWP::UserAgent->new;
	my $response = $agent->post( $path, @_ );
	if ( $response->is_success ) {
		$response->content;
	} else {
		return undef;
	}
}

sub server_open {
	my $class = shift;
	my $xml   = $class->post('/server/ServerStatus.xml.aspx');
	return 1 if $xml =~ /\bTrue\b/;
	return 0;
}

1;
