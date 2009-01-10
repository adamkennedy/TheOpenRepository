#!perl

use warnings;
use strict;
use 5.010_000;
use lib 't/lib';
use lib 'lib';
use Carp;
use Test::More tests => 3;
use Marpa::Test;

BEGIN {
	use_ok( 'Parse::Marpa' );
}

diag( "Testing Parse::Marpa $Parse::Marpa::VERSION, Perl $], $^X" );
my $status = Parse::Marpa::show_source_grammar_status();
my $status_line = 'Source Grammar Status: ' . $status;
ok($status, $status_line );
Marpa::Test::is($status, 'Stringified', 'Grammar is stringified');
