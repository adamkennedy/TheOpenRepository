#!/usr/bin/perl

# Tests for Process::Delegatable

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 18;
use File::Spec::Functions ':ALL';
use lib catdir('t', 'lib');
use Process::Launcher;

BEGIN {
	my $testdir = catdir('t', 'lib');
	ok( -d $testdir, 'Found test modules directory' );
	lib->import( $testdir );
}





#####################################################################
# Test Process::Backgroundable

use MyDelegatableProcess ();
SCOPE: {
	my $process = MyDelegatableProcess->new;
	isa_ok( $process, 'MyDelegatableProcess'  );
	isa_ok( $process, 'Process::Delegatable'  );
	isa_ok( $process, 'Process::Serializable' );
	isa_ok( $process, 'Process'               );
	can_ok( $process, 'delegate'              );

	# Trigger the backgrounding
	SCOPE: {
		local @Process::Delegatable::PERLCMD = (
			@Process::Delegatable::PERLCMD,
			'-I' . catdir('blib', 'arch'),
			'-I' . catdir('blib', 'lib'),
			'-I' . catdir('t',    'lib'),
			);
		ok( $process->delegate, '->delegate returns ok' );
	}

	# Should have set the data value
	is( $process->{somedata}, 'foo', '->data set as expected' );
	is( $process->{launcher_version}, $Process::Launcher::VERSION,
		'Used the correct Process::Launcher version' );
	is( $process->{process_version}, $Process::VERSION,
		'Used the correct Process version' );
}




# Repeat for the error case

SCOPE: {
	my $process = MyDelegatableProcess->new( pleasedie => 1 );
	isa_ok( $process, 'MyDelegatableProcess'  );
	isa_ok( $process, 'Process::Delegatable'  );
	isa_ok( $process, 'Process::Serializable' );
	isa_ok( $process, 'Process'               );
	can_ok( $process, 'delegate'              );

	# Trigger the backgrounding
	SCOPE: {
		local @Process::Delegatable::PERLCMD = (
			@Process::Delegatable::PERLCMD,
			'-I' . catdir('blib', 'lib'),
			'-I' . catdir('t',    'lib'),
			);
		ok( $process->delegate, '->delegate returns ok' );
	}

	# Should have set the data value
	is( $process->{somedata},  undef, '->data not set' );
	like( $process->{errstr}, qr/You wanted me to die/,
		'Got error message' );

}
