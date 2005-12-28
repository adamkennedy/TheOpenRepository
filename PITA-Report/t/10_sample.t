#!/usr/bin/perl -w

# Unit tests for the PITA::Report::Platform class

use strict;
use lib ();
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	unless ( $ENV{HARNESS_ACTIVE} ) {
		require FindBin;
		$FindBin::Bin = $FindBin::Bin; # Avoid a warning
		chdir catdir( $FindBin::Bin, updir() );
		lib->import(
			catdir('blib', 'lib'),
			catdir('blib', 'arch'),
			);
	}
}

use Test::More tests => 17;
use PITA::Report ();

my $XMLNS = PITA::Report->XMLNS;

my $EMPTY_FILE = catfile( 't', '10_empty.pita' );
ok( -f $EMPTY_FILE, 'Sample .pita file exists' );
ok( -f $EMPTY_FILE, 'Sample .pita file is readable' );

my $SINGLE_FILE = catfile( 't', '10_single.pita' );
ok( -f $SINGLE_FILE, 'Sample .pita file exists' );
ok( -f $SINGLE_FILE, 'Sample .pita file is readable' );





#####################################################################
# Validation

SKIP: {
	skip("Tests out of date", 3 );

	ok( PITA::Report->validate( \"<report xmlns='$XMLNS' />" ),
		'Sample (empty) string validates' );
	ok( PITA::Report->validate( $EMPTY_FILE ),
		'Sample (empty) file validates' );
	ok( PITA::Report->validate( $SINGLE_FILE ),
		'Sample (single) file validates' );

}





#####################################################################
# Practical Parsing Test

# Create a sample object from a minimal string
SCOPE: {
	my $report = PITA::Report->new( \<<"END_XML" );
<?xml version="1.0" encoding="ISO-8859-1"?><report xmlns='$XMLNS' />
END_XML
	isa_ok( $report, 'PITA::Report' );
	is( scalar($report->installs), 0, '->installs returns zero' );
	is_deeply( [ $report->installs ], [], '->installs returns null list' );
}

SKIP: {
	skip("Tests out of date", 7 );

	# Create a sample object from an empty file
	SCOPE: {
		my $report = PITA::Report->new( $EMPTY_FILE );
		isa_ok( $report, 'PITA::Report' );
		is( scalar($report->installs), 0, '->installs returns zero' );
		is_deeply( [ $report->installs ], [], '->installs returns null list' );
	}

	# Create a sample object from a file with a single report
	SCOPE: {
		my $report = PITA::Report->new( $SINGLE_FILE );
		isa_ok( $report, 'PITA::Report' );
		is( scalar($report->installs), 1, '->installs returns one' );
		my @installs = $report->installs;
		is( scalar(@installs), 1, '->installs returns one thing' );
		isa_ok( $installs[0], 'PITA::Report::Install' );
	}

}

exit(0);
