#!/usr/bin/perl

use strict;
use Carp;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
use Scalar::Util 'blessed';
use LWP::Online ':skip_all';
use File::Spec::Functions ':ALL';
BEGIN {
	unless ( $^O eq 'MSWin32' ) {
		plan( skip_all => 'Not on Win32' );
		exit(0);
	};
	unless ( $ENV{RELEASE_TESTING} ) {
		plan( skip_all => 'No RELEASE_TESTING: Skipping very long test' );
		exit(0);
	}
	if ( rel2abs( curdir() ) =~ m{\.} ) {
		plan( skip_all => 'Cannot be tested in a directory with an extension.' );
		exit(0);
	}
	if (rel2abs( catdir( qw( t tmp90 ) ) ) =~ m{\s}) {
		plan( skip_all => 'Cannot test successfully in a test directory with spaces' );
		exit(0);
	}
	plan( tests => 14 );
}

use t::lib::Test;



#####################################################################
# Complete Generation Run

# Create the dist object
my $dist = t::lib::Test->new2(90);
isa_ok( $dist, 't::lib::Test588' );

$SIG{__WARN__} = sub {
    $dist->trace_line(0, join(q{}, @_, Carp::longmess('Error is')));
    exit;
};

# Run the dist object, and ensure everything we expect was created
my $time = scalar localtime();
diag( "Building test dist @ $time, may take several hours... (sorry)" );
ok( eval { $dist->run; 1; }, '->run ok' );
if ( defined $@ ) {
	if ( blessed( $@ ) && $@->isa("Exception::Class::Base") ) {
		diag($@->as_string);
	} else {
		diag($@);
	}
}
$time = scalar localtime();
diag( "Test dist finished @ $time." );

# C toolchain files
ok(
	-f catfile( qw{ t tmp90 image c bin dmake.exe } ),
	'Found dmake.exe',
);
ok(
	-f catfile( qw{ t tmp90 image c bin startup Makefile.in } ),
	'Found startup',
);
ok(
	-f catfile( qw{ t tmp90 image c bin pexports.exe } ),
	'Found pexports',
);

# Perl core files
ok(
	-f catfile( qw{ t tmp90 image perl bin perl.exe } ),
	'Found perl.exe',
);

# Toolchain files
ok(
	-f catfile( qw{ t tmp90 image perl site lib LWP.pm } ),
	'Found LWP.pm',
);

# Custom installed file
ok(
	-f catfile( qw{ t tmp90 image perl site lib Config Tiny.pm } ),
	'Found Config::Tiny',
);

# Did we build 5.8.8?
ok(
	-f catfile( qw{ t tmp90 image perl bin perl58.dll } ),
	'Found Perl 5.8.8 DLL',
);
