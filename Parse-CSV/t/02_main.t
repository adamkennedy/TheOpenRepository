#!/usr/bin/perl -w

# Compile testing for Parse::CSV

use strict;
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
}

use Test::More tests => 16;
use Parse::CSV;

my $readfile = catfile( 't', 'data', 'simple.csv' );
ok( -f $readfile, "$readfile exists" );





#####################################################################
# Parsing a basic file in array ref mode

SCOPE: {
	my $csv = Parse::CSV->new(
		file => $readfile,
		);
	isa_ok( $csv, 'Parse::CSV' );
	is( $csv->row, 0, '->row returns 0' );
	is( $csv->errstr, '', '->errstr returns ""' );

	# Pull the first line
	my $fetch1 = $csv->fetch;
	is_deeply( $fetch1, [ qw{a b c d e} ], '->fetch returns as expected' );
	is( $csv->row, 1, '->row returns 1' );
	is( $csv->errstr, '', '->errstr returns ""' );

	# Pull the first line
	my $fetch2 = $csv->fetch;
	is_deeply( $fetch2, [ qw{this is also a sample} ], '->fetch returns as expected' );
	is( $csv->row, 2, '->row returns 2' );
	is( $csv->errstr, '', '->errstr returns ""' );

	# Pull the first line
	my $fetch3 = $csv->fetch;
	is_deeply( $fetch3, [ qw{1 2 3 4.5 5} ], '->fetch returns as expected' );
	is( $csv->row, 3, '->row returns 3' );
	is( $csv->errstr, '', '->errstr returns ""' );

	# Pull the first non-line
	my $fetch4 = $csv->fetch;
	is( $fetch4, undef, '->fetch returns undef' );
	is( $csv->row, 3, '->row returns 3' );
	is( $csv->errstr, '', '->errstr returns "" still' );
}

exit(0);
