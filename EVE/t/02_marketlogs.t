#!/usr/bin/perl

use strict;
BEGIN {
	$| = 1;
	$^W = 1;
}

use Test::More tests => 7;
use File::Spec::Functions ':ALL';
use EVE::Trade;
use EVE::MarketLogs;

my $directory = catdir('t', 'marketlogs');
ok( -d $directory, 'Found test directory' );

my @WHERE = ('where region_id = ?', '10000037');





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
EVE::Trade::Price->delete(@WHERE);
is( EVE::Trade::Price->count(@WHERE), 0, 'No records when starting' );

# Parse the market directory
ok( $logs->parse_all, '->parse_all ok' );
is( EVE::Trade::Price->count(@WHERE), 60, 'Inserted expected records' );
EVE::Trade::Price->delete(@WHERE);
is( EVE::Trade::Price->count(@WHERE), 0, 'Cleared test records' );
