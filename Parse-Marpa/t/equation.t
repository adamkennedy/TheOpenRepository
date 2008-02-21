# An ambiguous equation

use 5.010_000;
use strict;
use warnings;
use lib "../lib";

use Test::More tests => 8;

BEGIN {
	use_ok( 'Parse::Marpa' );
}

# The inefficiency (at least some of it) is deliberate.
# Passing up a duples of [ string, value ] and then
# assembling a final string at the top would be better
# than assembling the string then taking it
# apart at each step.  But I wanted to test having
# a start symbol that appears repeatedly on the RHS.

my $g = new Parse::Marpa::Grammar({
    start => "E",

    # Set max at 10 just in case there's an infinite loop.
    # This is for debugging, after all
    max_parses => 10,

    rules => [
	[ "E", [qw/E Op E/],
<<'EOCODE'
            my ($right_string, $right_value)
                = ($_->[2] =~ /^(.*)==(.*)$/);
            my ($left_string, $left_value)
                = ($_->[0] =~ /^(.*)==(.*)$/);
            my $op = $_->[1];
            my $value;
            if ($op eq "+") {
               $value = $left_value + $right_value;
            } elsif ($op eq "*") {
               $value = $left_value * $right_value;
            } elsif ($op eq "-") {
               $value = $left_value - $right_value;
            } else {
               croak("Unknown op: $op");
            }
            "(" . $left_string . $op . $right_string . ")==" . $value;
EOCODE
        ],
	[ "E", [qw/Number/],
<<'EOCODE'
           my $v0 = pop @$_;
           $v0 . "==" . $v0;
EOCODE
        ],
    ],
    terminals => [
	[ "Number" => { regex => qr/\d+/ } ],
	[ "Op" => { regex => qr/[-+*]/ } ],
    ],
    default_action => q{
         my $v_count = scalar @$_;
         return "" if $v_count <= 0;
         return $_->[0] if $v_count == 1;
         "(" . join(";", @$_) . ")";
    },
});

my $recce = new Parse::Marpa::Recognizer({grammar => $g});

my $op = $g->get_symbol("Op");
my $number = $g->get_symbol("Number");
$recce->earleme([$number, 2, 1]);
$recce->earleme([$op, "-", 1]);
$recce->earleme([$number, 0, 1]);
$recce->earleme([$op, "*", 1]);
$recce->earleme([$number, 3, 1]);
$recce->earleme([$op, "+", 1]);
$recce->earleme([$number, 1, 1]);

is( $g->show_rules(), <<'END_RULES', "Ambiguous Equation Rules" );
0: E -> E Op E
1: E -> Number
2: E['] -> E
END_RULES

is( $g->show_ii_SDFA(), <<'END_SDFA', "Ambiguous Equation SDFA" );
St0: 1,5
E ::= . E Op E
E ::= . Number
 <E> => St1 (2)
 <Number> => St4 (6)
St1: 2
E ::= E . Op E
 <Op> => St2 (3)
St2: 3
E ::= E Op . E
 empty => St0 (1,5)
 <E> => St3 (4)
St3: 4
E ::= E Op E .
St4: 6
E ::= Number .
St5: 7
E['] ::= . E
 empty => St0 (1,5)
 <E> => St6 (8)
St6: 8
E['] ::= E .
END_SDFA

my @expected = (
    '(((2-0)*3)+1)==7',
    '((2-(0*3))+1)==3',
    '((2-0)*(3+1))==8',
    '(2-((0*3)+1))==1',
    '(2-(0*(3+1)))==2',
);
my $evaler = new Parse::Marpa::Evaluator($recce);

for (my $i = 0; defined(my $value = $evaler->next()); $i++) {
    if ($i > $#expected) {
       fail("Ambiguous equation has extra value: " . $$value . "\n");
    } else {
        is($$value, $expected[$i], "Ambiguous Equation Value $i");
    }
}

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
