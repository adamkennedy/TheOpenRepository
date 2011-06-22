package EVE::API;

use 5.008;
use strict;
use warnings;
use XML::Tiny::DOM  1.1 ();
use LWP::UserAgent 6.02 ();

our $VERSION = '0.01';

use constant API_VERSION => 2;

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

sub char_asset_list {
	my $class = shift;
	my $xml   = $class->post( '/char/AssetList.xml.aspx', @_ );
	my $dom   = XML::Tiny::DOM->new("_TINY_XML_STRING_$xml");
	my @rows  = $dom->result->rowset->rows;

	$DB::single = 1;
}

1;
