#!/usr/bin/perl -w

# Basic test that ONLY loads the modules to ensure that all the code compiles

use strict;
use lib ();
use Params::Util '_SET';
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	unless ( $ENV{TEST_HARNESS} ) {
		# Special fast option for CGI environment, as FindBin won't work in
		# the web environments of some web hosts.
		if ( $ENV{SCRIPT_FILENAME} and $ENV{SCRIPT_FILENAME} =~ /^(.+\/)/ ) {
			chdir catdir( $1, updir() );
		} else {
			require FindBin;
			chdir catdir( $FindBin::Bin, updir() );
			$FindBin::Bin = $FindBin::Bin; # Avoid a "only used once" warning
		}

		# Set the lib path if we aren't in a harness
		lib->import(
			catdir('blib', 'arch'),
			catdir('blib', 'lib'),
			'lib',
			);
	}
}

use Test::More;
unless ( $ENV{GEOSOL_ROOT} and -d $ENV{GEOSOL_ROOT} ) {
	# We won't be able to find the GeoSol installation
	plan skip_all => 'GEOSOL_ROOT is not defined, or does not exist';
}

# Load the EmailSync module
use GeoSol::Process::EmailSync;

# Looks like we will be able to run the tests
plan tests => 2;





#####################################################################
# Main Tests

# Create the object
my $sync = GeoSol::Process::EmailSync->default;
isa_ok( $sync, 'GeoSol::Process::EmailSync' );

# Prepare
ok( $sync->prepare, '->prepare returns ok' );

1;
