use 5.010_000;
use Test::More tests => 2;

BEGIN {
	use_ok( 'Parse::Marpa' );
}

diag( "Testing Parse::Marpa $Parse::Marpa::VERSION, Perl $], $^X" );
my $status = Parse::Marpa::show_source_grammar_status();
my $status_line = "Source Grammar Status: " . $status;
ok($status, $status_line );
diag( $status_line );
