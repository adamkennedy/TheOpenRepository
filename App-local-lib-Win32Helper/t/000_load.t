#!perl

use Test::More tests => 1;

BEGIN {
    use_ok( 'local::lib::Win32' ) || print "Bail out!
";
}

diag( "Testing local::lib::Win32 $local::lib::Win32::VERSION, Perl $], $^X" );
