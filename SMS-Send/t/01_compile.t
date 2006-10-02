#!/usr/bin/perl -w

# Compile-testing for File::HomeDir

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 5;

ok( $] > 5.005, 'Perl version is 5.005 or newer' );

use_ok( 'SMS::Send'           );
use_ok( 'SMS::Send::Driver'   );
use_ok( 'SMS::Send::Test'     );
use_ok( 'SMS::Send::AU::Test' );

exit(0);
