#!/usr/bin/perl -w

# Basic test that ONLY loads the modules to ensure that all the code compiles

use strict;
use lib ();
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
	plan skip_all => 'GEOSOL_ROOT is not defined, or does not exist';
}

plan tests => 6;

# Check their perl version
ok( $] >= 5.006, "Your perl is new enough" );

# Does the module load
use_ok( 'GeoSol::Process::EmailSync' );
use_ok( 'Class::Inspector' );

ok( Class::Inspector->loaded('LVAS'),                 'LVAS module is loaded'                 );
ok( Class::Inspector->loaded('GeoSol'),               'GeoSol module is loaded'               );
ok( Class::Inspector->loaded('GeoSol::Entity::User'), 'GeoSol::Entity::User module is loaded' );
