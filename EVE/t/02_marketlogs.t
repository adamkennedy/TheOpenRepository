#!/usr/bin/perl

use strict;
BEGIN {
	$| = 1;
	$^W = 1;
}

use Test::More tests => 13;
use File::Spec::Functions ':ALL';
use EVE::Trade;
use EVE::MarketLogs;

my $directory = catdir('t', 'marketlogs');
ok( -d $directory, 'Found test directory' );

my @WHERE_MARKET = ('where region_id = ?', '10000037');
my @WHERE_PRICE  = ("where market_id in ( select market_id from market $WHERE_MARKET[0] )", $WHERE_MARKET[1]);





######################################################################
# Main tests

my $logs = EVE::MarketLogs->new(
	dir => $directory,
);
isa_ok( $logs, 'EVE::MarketLogs' );

# Find the test files
my @files = $logs->files;
is_deeply(
	\@files,
	[
		'Everyshore-1600mm Reinforced Titanium Plates I-2011.05.30 011717.txt',
		'Everyshore-Alloyed Tritanium Bar-2011.05.30 103726.txt',
	],
	'Found expected test file',
);

# Flush any existing test files from a previous run
EVE::Trade::Price->delete(@WHERE_PRICE);
EVE::Trade::Market->delete(@WHERE_MARKET);
is( EVE::Trade::Price->count(@WHERE_PRICE),  0, 'No records when starting' );
is( EVE::Trade::Market->count(@WHERE_MARKET), 0, 'No records when starting' );

# Parse the market directory
ok( $logs->parse_markets, '->parse_markets ok' );
is( EVE::Trade::Price->count(@WHERE_PRICE), 60, 'Inserted expected records' );
is( EVE::Trade::Market->count(@WHERE_MARKET), 2, 'Inserted expected records' );

# Run again, and expect it to be the same
ok( $logs->parse_markets, '->parse_markets ok' );
is( EVE::Trade::Price->count(@WHERE_PRICE), 60, 'Inserted expected records' );
is( EVE::Trade::Market->count(@WHERE_MARKET), 2, 'Inserted expected records' );

# Clean up the test data
EVE::Trade::Price->delete(@WHERE_PRICE);
EVE::Trade::Market->delete(@WHERE_MARKET);
is( EVE::Trade::Price->count(@WHERE_PRICE),  0, 'Cleared test records' );
is( EVE::Trade::Market->count(@WHERE_MARKET), 0, 'Cleared test records' );
