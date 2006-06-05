#!/usr/bin/perl -w

# Testing the support server implementation

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

use Test::More tests => 113;

use PITA                       ();
use PITA::Guest::SupportServer ();
use File::Remove               'remove';
use Params::Util               '_INSTANCE';
use LWP::UserAgent             ();
use HTTP::Request::Common      'GET', 'PUT';

# Create the test directory
my $testdir = catdir('t', '02_testdir');
if ( -d $testdir ) { remove( \1, $testdir ) }
ok( ! -d $testdir, "Testdir cleared at start of test script" );
ok( mkdir( $testdir ), 'mkdir returns ok' );
ok( -d $testdir, 'Created testdir' );
END { if ( -d $testdir ) { remove( \1, $testdir ); } }

# The common constructor params
my @params = (
	LocalAddr => '127.0.0.1',
	LocalPort => '54832',
	expected  => 1234,
	directory => $testdir,
);

# The common constructor params
my @noexpected = (
	LocalAddr => '127.0.0.1',
	LocalPort => '54832',
	directory => $testdir,
);

sub checkpoint {
	return unless grep { ! $_ } Test::Builder->new->summary;
	diag("Tests have failed, continuing could cause damage. Aborting");
	exit(255);
}



#####################################################################
# Check Signals

SCOPE: {
	# Validate that the signals we need are consistent.
	use Config;
	my $has_signals = defined($Config{sig_name});
	ok( $has_signals, "Platform supports signals" );
	unless ( $has_signals ) {
		BAIL_OUT("PITA::Guest::SupportServer requires an OS with signal support");
		exit(0);
	}

	# Set up the signame hash and array
	my %signo   = ();
	my @signame = ();
	my $i       = 0;
	foreach my $name ( split / /, $Config{sig_name} ) {
		$signo{$name} = $i;
		$signame[$i]  = $name;
		$i++;
	}

	# We need kill -15
	is( $signame[15], 'TERM', 'Signal 15 is SIGTERM' );
	is( $signame[9],  'KILL', 'Signal  9 is SIGKILL' );
}





#####################################################################
# In-process testing

checkpoint();

SCOPE: {
	# Create a new server
	my $server = PITA::Guest::SupportServer->new( @params );
	isa_ok( $server, 'PITA::Guest::SupportServer' );

	# Check the accessors
	is( $server->LocalAddr, '127.0.0.1', '->LocalAddr returns ok'   );
	is( $server->LocalPort, '54832',     '->LocalPort returns ok'   );
	is_deeply( [ $server->expected ], [ 1234 ], '->expected returns ok'    );
	is( $server->directory, $testdir,    '->directory returns ok'   );
	is( $server->daemon, undef,          '->daemon returns undef'   );
	is( $server->uri, "http://127.0.0.1:54832/", '->uri returns ok' );
	is( $server->pidfile, undef,         '->pidfile returns ok'     );

	# Stop should make no difference at this point
	ok( $server->stop, '->stop returns true' );

	#### SAME AS ABOVE
	is( $server->LocalAddr, '127.0.0.1', '->LocalAddr returns ok'   );
	is( $server->LocalPort, '54832',     '->LocalPort returns ok'   );
	is_deeply( [ $server->expected ], [ 1234 ], '->expected returns ok'    );
	is( $server->directory, $testdir,    '->directory returns ok'   );
	is( $server->daemon, undef,          '->daemon returns undef'   );
	is( $server->uri, "http://127.0.0.1:54832/", '->uri returns ok' );
	is( $server->pidfile, undef,         '->pidfile returns ok'     );
	#### SAME AS ABOVE

	# The parent methods at this point should have no values
	is( $server->parent_pid,     '', '->parent_pid matches expected' );
	is( $server->parent_pidfile, '', '->parent_pidfile matches expected' );





#####################################################################\
# Prepare the Server

	ok( $server->prepare, '->prepare returns true' );

	# Check the accessors
	is( $server->LocalAddr, '127.0.0.1', '->LocalAddr returns ok'   );
	is( $server->LocalPort, '54832',     '->LocalPort returns ok'   );
	is_deeply( [ $server->expected ], [ 1234 ], '->expected returns ok'    );
	is( $server->directory, $testdir,    '->directory returns ok'   );
	isa_ok( $server->daemon, 'HTTP::Daemon'                         );
	is( $server->uri, "http://127.0.0.1:54832/", '->uri returns ok' );
	isa_ok( $server->uri, 'URI' );
	like( $server->pidfile, qr/\d+\.pid$/, '->pidfile returns ok'   );
	ok( -f $server->pidfile, '->pidfile exists'                     );

	# Preparing again makes no changes
	ok( $server->prepare, 'Second ->prepare returns true' );

	#### SAME AS ABOVE
	is( $server->LocalAddr, '127.0.0.1', '->LocalAddr returns ok'   );
	is( $server->LocalPort, '54832',     '->LocalPort returns ok'   );
	is_deeply( [ $server->expected ], [ 1234 ], '->expected returns ok'    );
	is( $server->directory, $testdir,    '->directory returns ok'   );
	isa_ok( $server->daemon, 'HTTP::Daemon'                         );
	is( $server->uri, "http://127.0.0.1:54832/", '->uri returns ok' );
	isa_ok( $server->uri, 'URI' );
	like( $server->pidfile, qr/\d+\.pid$/, '->pidfile returns ok'   );
	ok( -f $server->pidfile, '->pidfile exists'                     );
	### SAME AS ABOVE

	# Stopping a prepared server should release the resources
	my $pidfile = $server->pidfile;
	ok( $server->stop, '->stop returns true' );
	is( $server->daemon, undef,          '->daemon returns undef'   );	
	is( $server->pidfile, undef,         '->pidfile returns undef'  );
	ok( ! -f $pidfile, 'pid file is actually released'                );
}





#####################################################################
# Check unusual destruction frees the resources

checkpoint();

SCOPE: {
	my $server = PITA::Guest::SupportServer->new( @params );
	isa_ok( $server, 'PITA::Guest::SupportServer' );
	ok( $server->prepare, '->prepare returns ok' );
	my $pidfile = $server->pidfile;
	ok( -f $pidfile, 'PID file exists before DESTROY' );
	undef $server;
	sleep 1;
	ok( ! -f $pidfile, 'PID file removed after DESTROY' );
}





#####################################################################
# Check adding expected report AFTER constructor

checkpoint();

SCOPE: {
	my $server = PITA::Guest::SupportServer->new( @noexpected );
	isa_ok( $server, 'PITA::Guest::SupportServer' );
	is_deeply( [ $server->expected ], [], '->expected returns nothing' );
	ok( $server->expect(1234), '->expect(1234) returns true' );
	is_deeply( [ $server->expected ], [ 1234 ], '->expected returns nothing' );
	ok( $server->prepare, '->prepare returns true' );
}





#####################################################################
# Launch the server, full on

checkpoint();

SCOPE: {
	my $server = PITA::Guest::SupportServer->new( @params );

	# Triple check inheritance
	isa_ok( $server, 'PITA::Guest::SupportServer' );
	isa_ok( $server, 'Process' );
	isa_ok( $server, 'Process::Backgroundable' );
	ok( _INSTANCE($server, 'Process'), '->isa Process' );
	ok( _INSTANCE($server, 'Process::Backgroundable'), '->isa Backgroundable' );

	# Launch the backgrounded server
	SCOPE: {
		local @Process::Backgroundable::PERLCMD = (
			@Process::Backgroundable::PERLCMD,
			'-I' . catdir('blib', 'arch'),
			'-I' . catdir('blib', 'lib'),
			$ENV{HARNESS_ACTIVE} ? () : ('-I' . catdir('lib')),
			);
		ok( $server->background, '->background returns ok' );
	}

	# Find the PID file
	ok( opendir( TESTDIR, $testdir ), 'Opened test directory' );
	my @files = readdir( TESTDIR );
	ok( closedir( TESTDIR ), 'Closed test directory' );
	@files = map { /(\d+)\.pid$/ ? $1 : () } @files;
	is( scalar(@files), 1, 'Found one pid file' );
	my $pid     = $files[0];
	my $pidfile = catfile( $testdir, $pid . ".pid" );
	ok( kill( 0 => $pid ), "Process $pid detected" );
	ok( -f $pidfile, 'Confirm pid file creation' );

	# TERMinate it.
	# The server should be set to stop on sigterm
	ok( kill( 15 => $pid ), 'Sent SIGTERM to support server' );
	sleep 3;

	# The file and process should both be gone
	ok( ! -f $pidfile, 'PID file has been removed'    );
	ok( ! kill( 0 => $pid ), 'Zombie has been reaped' );

	### Repeat but delete the file to kill
	# Launch the backgrounded server
	SCOPE: {
		local @Process::Backgroundable::PERLCMD = (
			@Process::Backgroundable::PERLCMD,
			'-I' . catdir('blib', 'arch'),
			'-I' . catdir('blib', 'lib'),
			$ENV{HARNESS_ACTIVE} ? () : ('-I' . catdir('lib')),
			);
		ok( $server->background, '->background returns ok' );
	}

	# Find the PID file
	ok( opendir( TESTDIR, $testdir ), 'Opened test directory' );
	@files = readdir( TESTDIR );
	ok( closedir( TESTDIR ), 'Closed test directory' );
	@files = map { /(\d+)\.pid$/ ? $1 : () } @files;
	is( scalar(@files), 1, 'Found one pid file' );
	$pid     = $files[0];
	$pidfile = catfile( $testdir, $pid . ".pid" );
	ok( kill( 0 => $pid ), "Process $pid detected" );
	ok( -f $pidfile, 'Confirm pid file creation' );

	# Terminate by deleting the PID file
	ok( File::Remove::remove( $pidfile ), 'Deleted the PID file' );
	sleep 3;

	# The file and process should both be gone
	ok( ! -f $pidfile, 'PID file is still has been removed' );
	ok( ! kill( 0 => $pid ), 'Zombie has been reaped' );
}





#####################################################################
# Launch the server, and send an actual file to it

checkpoint();

SCOPE: {
	my $server = PITA::Guest::SupportServer->new( @params );
	isa_ok( $server, 'PITA::Guest::SupportServer' );

	# Launch the backgrounded server
	SCOPE: {
		local @Process::Backgroundable::PERLCMD = (
			@Process::Backgroundable::PERLCMD,
			'-I' . catdir('blib', 'arch'),
			'-I' . catdir('blib', 'lib'),
			$ENV{HARNESS_ACTIVE} ? () : ('-I' . catdir('lib')),
			);
		ok( $server->background, '->background returns ok' );
	}

	# Find the PID file
	ok( opendir( TESTDIR, $testdir ), 'Opened test directory' );
	my @files = readdir( TESTDIR );
	ok( closedir( TESTDIR ), 'Closed test directory' );
	@files = map { /(\d+)\.pid$/ ? $1 : () } @files;
	is( scalar(@files), 1, 'Found one pid file' );
	my $pid     = $files[0];
	my $pidfile = catfile( $testdir, $pid . ".pid" );
	ok( kill( 0 => $pid ), "Process $pid detected" );
	ok( -f $pidfile, 'Confirm pid file creation' );

	# Compare with the parent methods
	is( $server->parent_pid,     $pid,     '->parent_pid matches expected'     );
	is( $server->parent_pidfile, $pidfile, '->parent_pidfile matches expected' );

	# Get the root
	my $agent   = LWP::UserAgent->new;
	isa_ok( $agent, 'LWP::UserAgent' );
	my $request = GET( $server->uri );
	isa_ok( $request, 'HTTP::Request' );
	my $response = $agent->request( $request );
	isa_ok( $response, 'HTTP::Response' );
	ok( $response->is_success, 'SupportServer returns success' );
	like( $response->content, qr/PITA::Guest::SupportServer/,
		'GET / returns a pong' );

	# It shouldn't die just from a GET /
	sleep 1;
	ok( kill( 0 => $pid ), "Process $pid still running after GET /" );
	ok( -f $pidfile, 'Confirm pid file unchanged' );	

	# Send the expected report file
	my $report_xml = <<'END_XML';
<?xml version='1.0' encoding='UTF-8'?>
<report xmlns='$XMLNS' />
END_XML

	$request = PUT( $server->uri . '1234',
		content_type   => 'application/xml',
		content_length => length($report_xml),
		content        => $report_xml,
		);
	isa_ok( $request, 'HTTP::Request' );
	$response = $agent->request( $request );
	isa_ok( $response, 'HTTP::Response' );
	ok( $response->is_success, 'SupportServer returns success' );

	# Give it a second to shut down
	sleep 1;

	# Has the server shut down
	my $has_shutdown = ! kill( 0 => $pid );
	ok( $has_shutdown, "Process $pid has shut down" );
	unless ( $has_shutdown ) {
		kill( 15 => $pid ); # Kill it anyway
		sleep 1;
		if ( kill( 0 => $pid ) ) {
			# Harder
			kill( 9 => $pid );
		}
	}

	# Did it write the file to the expected location
	my $output = catfile( $testdir, '1234.pita' );
	ok( -f $output, 'File was created ok' );
	ok( open( TESTFILE, '<', $output ), 'Opened test file' );
	my $content;
	SCOPE: {
		local $/;
		$content = <TESTFILE>;
	}
	ok( close( TESTFILE ), 'Closed test file' );
	is( $content, $report_xml, 'Written file matches original file' );

	# Note:
	# Don't need to remove the file, it is in supportserver dir,
	# so it will be removed automatically.
}




#####################################################################
# Run the equivalent of a ping test

checkpoint();

SCOPE: {
	my $server = PITA::Guest::SupportServer->new( @noexpected );
	isa_ok( $server, 'PITA::Guest::SupportServer' );

	# Launch the backgrounded server
	SCOPE: {
		local @Process::Backgroundable::PERLCMD = (
			@Process::Backgroundable::PERLCMD,
			'-I' . catdir('blib', 'arch'),
			'-I' . catdir('blib', 'lib'),
			$ENV{HARNESS_ACTIVE} ? () : ('-I' . catdir('lib')),
			);
		ok( $server->background, '->background returns ok' );
	}

	# Compare with the parent methods
	ok( $server->parent_pid,     'Found the server' );

	# Ping the server
	my $agent   = LWP::UserAgent->new;
	isa_ok( $agent, 'LWP::UserAgent' );
	my $request = GET( $server->uri );
	isa_ok( $request, 'HTTP::Request' );
	my $response = $agent->request( $request );
	isa_ok( $response, 'HTTP::Response' );
	ok( $response->is_success, 'SupportServer returns success' );
	like( $response->content, qr/PITA::Guest::SupportServer/,
		'GET / returns a pong' );

	# Server should have stopped
	ok( ! $server->parent_pid, 'Server has stopped' );
}

exit(0);
