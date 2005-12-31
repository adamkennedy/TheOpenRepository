#!/usr/bin/perl

# Utility script. Takes a URL and posts an XML file to it.

my $url = shift @ARGV or die "No URL provided";
my $xml = "<?xml version='1.0' encoding='UTF-8'?><report xmlns='http://ali.as/xml/schema/pita-xml/0.03' />";

# Create the request
use LWP::UserAgent ();
use HTTP::Request::Common 'PUT';

my $agent = LWP::UserAgent->new;
my $rv = $agent->request(PUT $url,
	content_type   => 'application/xml',
	content_length => length($xml),
	content        => $xml,
	);

1;
