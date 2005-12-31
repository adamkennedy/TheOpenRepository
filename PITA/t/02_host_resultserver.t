#!/usr/bin/perl -w

# Compile-testing for PITA

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
			'lib',
			);
	}
}

use Test::More tests => 9;

use File::Remove 'remove';
use Params::Util '_POSINT';

use_ok( 'PITA' );





#####################################################################
# Create a request server

# Create the write directory
my $pid = 0;
my $dir = catdir( 't', 'resultserver' );
      remove( \1, $dir ) if -d $dir;
END { remove( \1, $dir ) if (-d $dir and $childpid) }
ok( mkdir($dir), "Created test directory $dir" );

# Create the result server
my $server = PITA::Host::ResultServer->new(
	LocalAddr => '127.0.0.1',
	directory => $dir,
	expected  => '1234',
	);
isa_ok( $server, 'PITA::Host::ResultServer' );
is( $server->LocalAddr, '127.0.0.1', "Got back expected LocalAddr" );
ok( _POSINT($server->LocalPort),     "Got a LocalPort (" . $server->LocalPort . ")" );
is( $server->directory, $dir,        "Got back directory" );
is_deeply( [ $server->expected ], [ 1234 ], "Got back expected" );
isa_ok( $server->daemon, 'HTTP::Daemon' );
isa_ok( $server->uri,    'URI'          );

# Launch it
print "Starting up at " . $server->uri . "\n";
$server->start;

$childpid = $server->{child};

# Pause the parent, so we can debug the child
sleep( 100000 ) if $childpid;

exit(0);
