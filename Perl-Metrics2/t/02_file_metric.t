#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 9;
use File::Spec::Functions ':ALL';
use Perl::Metrics2;

my $file = rel2abs(catfile('t', 'data', 'hello.pl'));
ok( -f $file, "Found test file $file" );

# Clear all existing data from the database
ok(
	Perl::Metrics2::FileMetric->truncate,
	'->truncate ok',
);
is(
	Perl::Metrics2::FileMetric->count, 0,
	'->count returns zero',
);

# Process the sample file
ok(
	Perl::Metrics2->process_file($file),
	'->process_file ok',
);
is(
	Perl::Metrics2::FileMetric->count, 3,
	'->count returns correctly',
);
my @rows = Perl::Metrics2::FileMetric->select;
is( scalar(@rows), 3, 'Returned three rows' );
isa_ok( $rows[0], 'Perl::Metrics2::FileMetric' );
isa_ok( $rows[1], 'Perl::Metrics2::FileMetric' );
isa_ok( $rows[2], 'Perl::Metrics2::FileMetric' );
