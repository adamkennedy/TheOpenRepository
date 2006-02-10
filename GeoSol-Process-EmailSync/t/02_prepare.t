#!/usr/bin/perl -w

# Basic test that ONLY loads the modules to ensure that all the code compiles

use strict;
use lib ();
use Params::Util          ':ALL';
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
my @TEST_LVAS_SERVER = $ENV{TEST_LVAS_SERVER} ? split(/,\s*/, $ENV{TEST_LVAS_SERVER}) : ();
unless ( @TEST_LVAS_SERVER == 7 ) {
	# We won't be able to connect to LVAS
	plan skip_all => 'TEST_LVAS_SERVER is not defined or not correct';
}

# Load the EmailSync module
use GeoSol::Process::EmailSync;

# Looks like we will be able to run the tests
plan tests => 24;

# LVAS test constants
my $LVAS_HOST     = $TEST_LVAS_SERVER[0];
my $LVAS_PORT     = $TEST_LVAS_SERVER[1];
my $LVAS_LOGIN    = $TEST_LVAS_SERVER[2];
my $LVAS_PASSWORD = $TEST_LVAS_SERVER[3];
my $LVAS_DOMAIN   = $TEST_LVAS_SERVER[4];





#####################################################################
# Main Tests

# Create the object
my $sync = GeoSol::Process::EmailSync->new(
	lvas_host     => $LVAS_HOST,
	lvas_port     => $LVAS_PORT,
	lvas_login    => $LVAS_LOGIN,
	lvas_password => $LVAS_PASSWORD,
	lvas_domain   => $LVAS_DOMAIN,
	);
isa_ok( $sync, 'GeoSol::Process::EmailSync' );

# Check accessors
is( $sync->lvas_host,     $LVAS_HOST,     '->lvas_host returns as expected'     );
is( $sync->lvas_port,     $LVAS_PORT,     '->lvas_port returns as expected'     );
is( $sync->lvas_login,    $LVAS_LOGIN,    '->lvas_login returns as expected'    );
is( $sync->lvas_password, $LVAS_PASSWORD, '->lvas_password returns as expected' );
is( $sync->lvas_domain,   $LVAS_DOMAIN,   '->lvas_domain returns as expected'   );
isa_ok( $sync->lvas, 'LVAS' );
is( $sync->users,            undef, '->users returns undef'            );
is( $sync->vs_id,            undef, '->vs_id returns undef'            );
is( $sync->dns_id,           undef, '->dns_id returns undef'           );
is( $sync->existing_aliases, undef, '->existing_aliases returns undef' );
is( $sync->wanted_aliases,   undef, '->wanted_aliases returns undef'   );

# Prepare to execute
ok( $sync->prepare, '->prepare returns ok' );

# Check accessors
is( $sync->lvas_host,     $LVAS_HOST,     '->lvas_host returns as expected'     );
is( $sync->lvas_port,     $LVAS_PORT,     '->lvas_port returns as expected'     );
is( $sync->lvas_login,    $LVAS_LOGIN,    '->lvas_login returns as expected'    );
is( $sync->lvas_password, $LVAS_PASSWORD, '->lvas_password returns as expected' );
is( $sync->lvas_domain,   $LVAS_DOMAIN,   '->lvas_domain returns as expected'   );
isa_ok( $sync->lvas, 'LVAS' );
ok( _SET($sync->users,      'GeoSol::Entity::User'), '->users returns a set of users' );
ok( _POSINT($sync->vs_id),  '->vs_id returns a POSINT'  );
ok( _POSINT($sync->dns_id), '->dns_id returns a POSINT' );
ok( _HASH0($sync->existing_aliases), '->existing_aliases returns a HASH' );
ok( _HASH0($sync->wanted_aliases),   '->wanted_aliases returns a HASH'   );

1;
