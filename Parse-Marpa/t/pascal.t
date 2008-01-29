use 5.010_000;
# variations on
# the example grammar in Aycock/Horspool "Practical Earley Parsing",
# _The Computer Journal_, Vol. 45, No. 6, pp. 620-630,

use strict;
use warnings;
use lib "../lib";

use Test::More tests => 8;

BEGIN {
	use_ok( 'Parse::Marpa' );
}

sub ah_extended {
     my $n = shift;

    my $g = new Parse::Marpa(
        start => "S",
        rules => [
            [ "S", [("A")x$n] ],
            [ "A", [qw/a/] ],
            [ "A", [qw/E/] ],
            [ "E" ],
        ],
        terminals => [
            [ "a" => { regex => qr/a/ } ],
        ],
        volatile => 1,
        # no warnings for $n equals zero
        warnings => ($n ? 1 : 0),
    );

    my $parse = new Parse::Marpa::Parse(grammar => $g);

    my $a = $g->get_symbol("a");
    for (0 .. $n) { $parse->earleme([$a, "a", 1]); }

    my @parse_counts;
    for my $loc (0 .. $n) {
        my $parse_number = 0;
        die("Cannot initialize parse at location $loc") unless $parse->initial($loc);

        # An arbitrary maximum is put on the number of parses -- this is for
        # debugging, and infinite loops happen.
        PARSE: for my $parse_number (1 .. 999) {
           $parse_counts[$loc]++;
           last PARSE unless $parse->next();
        }
    }
    join(" ", @parse_counts);
}

my @answers = (
"1",
"1 1",
"1 2 1",
"1 3 3 1",
"1 4 6 4 1",
"1 5 10 10 5 1",
"1 6 15 20 15 6 1",
"1 7 21 35 35 21 7 1",
"1 8 28 56 70 56 28 8 1",
"1 9 36 84 126 126 84 36 9 1",
"1 10 45 120 210 252 210 120 45 10 1",
);

for $a (0 .. 5, 10) {
  is(ah_extended($a), $answers[$a], "Row $a of Pascal's triangle matches parse counts");
}

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
