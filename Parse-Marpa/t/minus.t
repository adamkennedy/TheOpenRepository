use 5.010_000;

# An ambiguous equation,
# this time using the lexer

use strict;
use warnings;
use lib "../lib";

use Test::More tests => 11;

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

    # Set max_parses to 20 in case there's an infinite loop.
    # This is for debugging, after all
    max_parses => 20,

    rules => [
	[ "E", [qw/E Minus E/],
<<'EOCODE'
    my ($right_string, $right_value)
        = ($_->[2] =~ /^(.*)==(.*)$/);
    my ($left_string, $left_value)
        = ($_->[0] =~ /^(.*)==(.*)$/);
    my $value = $left_value - $right_value;
    "(" . $left_string . "-" . $right_string . ")==" . $value;
EOCODE
        ],
	[ "E", [qw/E MinusMinus/],
<<'EOCODE'
    my ($string, $value)
        = ($_->[0] =~ /^(.*)==(.*)$/);
    "(" . $string . "--" . ")==" . $value--;
EOCODE
        ],
	[ "E", [qw/MinusMinus E/],
<<'EOCODE'
    my ($string, $value)
        = ($_->[1] =~ /^(.*)==(.*)$/);
    "(" . "--" . $string . ")==" . --$value;
EOCODE
        ],
	[ "E", [qw/Minus E/],
<<'EOCODE'
    my ($string, $value)
        = ($_->[1] =~ /^(.*)==(.*)$/);
    "(" . "-" . $string . ")==" . -$value;
EOCODE
        ],
	[ "E", [qw/Number/],
<<'EOCODE'
    my $value = $_->[0];
    "$value==$value";
EOCODE
        ],
    ],
    terminals => [
	[ "Number" => { regex => qr/\d+/ } ],
	[ "Minus" => { regex => qr/[-]/ } ],
	[ "MinusMinus" => { regex => qr/[-][-]/ } ],
    ],
    default_action =>
<<'EOCODE',
     my $v_count = scalar @$_;
     return "" if $v_count <= 0;
     return $_->[0] if $v_count == 1;
     "(" . join(";", @$_) . ")";
EOCODE
});

my $recce = new Parse::Marpa::Recognizer({
    grammar => $g,
});

is( $g->show_rules(), <<'END_RULES', "Minuses Equation Rules" );
0: E -> E Minus E
1: E -> E MinusMinus
2: E -> MinusMinus E
3: E -> Minus E
4: E -> Number
5: E['] -> E
END_RULES

is( $g->show_ii_QDFA(), <<'END_QDFA', "Minuses Equation QDFA" );
Start States: St0; St5
St0: predict; 1,5,8,11,14
E ::= . E Minus E
E ::= . E MinusMinus
E ::= . MinusMinus E
E ::= . Minus E
E ::= . Number
 <E> => St7
 <Minus> => St0; St2
 <MinusMinus> => St0; St11
 <Number> => St4
St1: 10
E ::= MinusMinus E .
St2: 12
E ::= Minus . E
 <E> => St3
St3: 13
E ::= Minus E .
St4: 15
E ::= Number .
St5: 16
E['] ::= . E
 <E> => St6
St6: 17
E['] ::= E .
St7: 2,6
E ::= E . Minus E
E ::= E . MinusMinus
 <Minus> => St0; St8
 <MinusMinus> => St10
St8: 3
E ::= E Minus . E
 <E> => St9
St9: 4
E ::= E Minus E .
St10: 7
E ::= E MinusMinus .
St11: 9
E ::= MinusMinus . E
 <E> => St1
END_QDFA

my @expected = (
    '(((6--)--)-1)==5',
    '((6--)-(--1))==6',
    '(6-(--(--1)))==7',
    '(6-(--(-(-1))))==6',
    '((6--)-(-(-1)))==5',
    '(6-(-(-(--1))))==6',
    '(6-(-(-(-(-1)))))==5',
    '(6-(-(--(-1))))==4',
);

my $fail_offset = $recce->text(\("6-----1"));
if ($fail_offset >= 0) {
   die("Parse failed at offset $fail_offset");
}

my $evaler = new Parse::Marpa::Evaluator($recce);
die("Could not initialize parse") unless $evaler;

for (my $i = 0; defined(my $value = $evaler->next()); $i++) {
    if ($i > $#expected) {
       fail("Minuses equation has extra value: " . $$value . "\n");
    } else {
        is($$value, $expected[$i], "Minuses Equation Value $i");
    }
}

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
