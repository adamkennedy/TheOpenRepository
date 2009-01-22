#!perl

use Test::More tests => 1;

BEGIN {
	use_ok( 'Test::Weaken' );
}

diag( "Testing Test::Weaken $Test::Weaken::VERSION, Perl $], $^X" );
