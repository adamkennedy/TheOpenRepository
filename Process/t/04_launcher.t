#!/usr/bin/perl

# Compile-testing for Process::Launcher

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 23;
use File::Spec::Functions ':ALL';
use lib catdir('t', 'lib');

my @base_cmd = ( $^X,
	'-I' . catdir('blib', 'lib'),
	'-I' . catdir('lib'),
	'-I' . catdir('t',    'lib'),
	'-MProcess::Launcher',
	);

BEGIN {
	my $testdir = catdir('t', 'lib');
	ok( -d $testdir, 'Found test modules directory' );
	lib->import( $testdir );\

	use_ok( 'Process::Launcher' );
}





#####################################################################
# Simulated test the Process::Launcher 'run' command

use_ok( 'MySimpleProcess' );
SCOPE: {
	@ARGV = qw{MySimpleProcess foo bar};
	my $class  = Process::Launcher::load(shift @ARGV);
	is( $class, 'MySimpleProcess', 'load(MySimpleProcess) returned ok' );
	my $object = $class->new( @ARGV );
	isa_ok( $object, $class );
}





#####################################################################
# Live test the Process::Launcher 'run' command

use IPC::Run3 ();
use_ok( 'MyStorableProcess' );
SCOPE: {
	# Build the complex, uglyish cmd list
	my @cmd = ( @base_cmd, '-e run', 'MyStorableProcess', 'foo' => 'bar' );
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
	my @cmd = ( @base_cmd, '-e run3', 'MyStorableProcess' );
	my $inp  = "foo2=bar2\n";
	my $out = "";
	my $err = '';
	ok( IPC::Run3::run3( \@cmd, \$inp, \$out, \$err ), 'run3 returns true' );
	is( $out, "OK\n", 'STDOUT gets OK' );
	is( $err, "foo2=bar2\nprepare=1\n", "STDERR gets expected output" );
}




#####################################################################
# Test the Process::Launcher 'serialized' command with Storable

use Storable ();
ok( MyStorableProcess->isa('Process::Storable'),
	'Confirm MyStorableProcess isa Process::Storable' );
SCOPE: {
	my $object = MyStorableProcess->new( 'foo3' => 'bar3' );
	isa_ok( $object, 'MyStorableProcess' );
	isa_ok( $object, 'Process::Storable' );
	isa_ok( $object, 'Process'           );

	# Get the Storablised version
	my @cmd = ( @base_cmd, '-e serialized', 'MyStorableProcess' );
	my $inp = File::Temp::tempfile();
	my $out = File::Temp::tempfile();
	ok( $object->serialize( $inp ), '->serialize returns ok' );
	ok( seek( $inp, 0, 0 ), 'Seeked on tempfile for input' );

	my $err = '';
	ok( IPC::Run3::run3( \@cmd, $inp, $out, \$err ), 'serialized returns true' );
	is( $err, "foo3=bar3\nprepare=1\n", "STDERR gets expected output" );
	ok( seek( $out, 0, 0 ), 'seeked STDOUT to 0' );
	my $header = <$out>;
	is( $header, "OK\n", 'STDOUT has OK header' );

	SKIP: {
		skip("Nothing to deserialize", 1) unless $header eq "OK\n";

		my $after = MyStorableProcess->deserialize( $out );
		is_deeply( $after,
			(bless {
				foo3    => 'bar3',
				prepare => 1,
				run     => 1,
			}, 'MyStorableProcess'),
			'Returned object matches expected' );
	}
}
