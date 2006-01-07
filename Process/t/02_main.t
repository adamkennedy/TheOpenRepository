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

use lib catdir('t', 'lib');
use Test::More tests => 27;

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





#####################################################################
# Test Process::Backgroundable

# Create the test file
use File::Remove ();
my $background = catfile('t', 'background_file.txt');
unless ( -f $background ) {
	open( FILE, '>', $background ) or die "Failed to open test file to write";
	print FILE "Test content\n";
	close FILE;
}
ok( -f $background, 'Background test file exists' );
END { if ( -f $background ) { File::Remove::remove($background) } }

use MyBackgroundProcess ();
SCOPE: {
	# Create the file-removal backgrounded process
	my $remover = MyBackgroundProcess->new( file => $background );
	isa_ok( $remover, 'MyBackgroundProcess'     );
	isa_ok( $remover, 'Process'                 );
	isa_ok( $remover, 'Process::Backgroundable' ); 
	can_ok( $remover, 'background'              );

	# Trigger the backgrounding
	SCOPE: {
		local @Process::Backgroundable::PERLCMD = (
			@Process::Backgroundable::PERLCMD,
			'-I' . catdir('blib', 'lib'),
			'-I' . catdir('t',    'lib'),
			);
		ok( $remover->background, '->background returns ok' );
	}

	# The remove will wait 1 second.
	# Check that the file still exists, and thus the
	# background call didn't block.
	ok( -f $background, 'Test file still exists after ->background call' );

	# Wait 3 seconds to allow for startup and run time
	sleep 3;

	# Check the file is gone now
	ok( ! -f $background, 'Test file is removed correctly' );
}

exit(0);
