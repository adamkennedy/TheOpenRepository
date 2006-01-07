#!/usr/bin/perl -w

# Compile-testing for Process

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
			'lib',
			);
	}
}

use Test::More tests => 19;

my @base_cmd = ( $^X,
	'-I' . catdir('blib', 'lib'),
	'-I' . catdir('lib'),
	'-I' . catdir('t',    'lib'),
	'-MProcess::Launcher',
	);

BEGIN {
	my $testdir = catdir('t', 'lib');
	ok( -d $testdir, 'Found test modules directory' );
	lib->import( $testdir );
}





#####################################################################
# Test the base Process class

use Process;
SCOPE: {
	my $object = Process->new;
	isa_ok( $object, 'Process' );
	ok( $object->prepare, '->prepare returns true' );
	ok( $object->run,     '->run returns true'     );
}





#####################################################################
# Test the Process::Launcher 'run' command

use IPC::Run3 ();
use_ok( 'MySimpleProcess' );
SCOPE: {
	# Build the complex, uglyish cmd list
	my @cmd = ( @base_cmd, '-e run', 'MySimpleProcess', 'foo' => 'bar' );
	my $out = '';
	my $err = '';
	ok( IPC::Run3::run3( \@cmd, \undef, \$out, \$err ), 'run3 returns true' );
	is( $out, "OK\n", 'STDOUT gets OK' );
	is( $err, "foo=bar\nprepare=1\n", "STDERR gets expected output" );
}





#####################################################################
# Test the Process::Launcher 'run3' command

SCOPE: {
	# Build the complex, uglyish cmd list
	my @cmd = ( @base_cmd, '-e run3', 'MySimpleProcess' );
	my $inp  = "foo2=bar2\n";
	my $out = "";
	my $err = '';
	ok( IPC::Run3::run3( \@cmd, \$inp, \$out, \$err ), 'run3 returns true' );
	is( $out, "OK\n", 'STDOUT gets OK' );
	is( $err, "foo2=bar2\nprepare=1\n", "STDERR gets expected output" );
}





#####################################################################
# Test the Process::Launcher 'storable' command

use Storable ();
SCOPE: {
	my $object = MySimpleProcess->new( 'foo3' => 'bar3' );
	isa_ok( $object, 'MySimpleProcess' );

	# Get the Storablised version
	my @cmd = ( @base_cmd, '-e storable' );
	my $inp = File::Temp::tempfile();
	my $out = File::Temp::tempfile();
	ok( scalar(Storable::nstore_fd( $object, $inp )), 'nstore_fd ok' );
	ok( seek( $inp, 0, 0 ), 'Seeked on tempfile for input' );
	my $err = '';
	ok( IPC::Run3::run3( \@cmd, $inp, $out, \$err ), 'storable returns true' );
	is( $err, "foo3=bar3\nprepare=1\n", "STDERR gets expected output" );
	ok( seek( $out, 0, 0 ), 'seeked STDOUT to 0' );
	my $header = <$out>;
	is( $header, "OK\n", 'STDOUT has OK header' );

	my $after = Storable::fd_retrieve( $out );
	is_deeply( $after,
		(bless {
			foo3    => 'bar3',
			prepare => 1,
			run     => 1,
		}, 'MySimpleProcess'),
		'Returned object matches expected' );
}

exit(0);
