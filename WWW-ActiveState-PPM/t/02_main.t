#!/usr/bin/perl

# Compile testing for WWW::ActiveState::PPM

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use LWP::Online ':skip_all';
use Test::More tests => 10;
use WWW::ActiveState::PPM;

# Create the scraper
my $scrape = WWW::ActiveState::PPM->new( trace => 1 );
isa_ok( $scrape, 'WWW::ActiveState::PPM' );
is( $scrape->trace, '', '->trace is false by default' );
is( $scrape->version, '5.10', '->version is 5.10 by default' );

# Run the scraping
$scrape->run;

1;
