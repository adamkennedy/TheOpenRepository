#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
BEGIN {
	unless ( $^O eq 'MSWin32' ) {
		plan( skip_all => 'Not on Win32' );
		exit(0);
	}
	plan( tests => 10 );
}

use File::Spec::Functions ':ALL';
use t::lib::Test;





#####################################################################
# Constructor Test

# Create the dist object
my $dist = t::lib::Test->new2(2);
isa_ok( $dist, 't::lib::Test2' );

# Run the dist object, and ensure everything we expect was created
ok( $dist->run, '->run ok' );
