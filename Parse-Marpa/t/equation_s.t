# An ambiguous equation

use 5.010_000;
use strict;
use warnings;
use lib "../lib";
use English;

use Test::More tests => 6;

BEGIN {
	use_ok( 'Parse::Marpa' );
}

# The inefficiency (at least some of it) is deliberate.
# Passing up a duples of [ string, value ] and then
# assembling a final string at the top would be better
# than assembling the string then taking it
# apart at each step.  But I wanted to test having
# a start symbol that appears repeatedly on the RHS.

my $source; { local($RS) = undef; $source = <DATA> };

my $g = new Parse::Marpa::Grammar({

    # Set max at 10 in case there's an infinite loop.
    # This is for debugging, after all
    max_parses => 10,

    mdl_source => \$source,
});

my $recce = new Parse::Marpa::Recognizer({grammar => $g});

my $op = Parse::Marpa::MDL::get_symbol($g, "Op");
my $number = Parse::Marpa::MDL::get_symbol($g, "Number");
$recce->earleme([$number, 2, 1]);
$recce->earleme([$op, "-", 1]);
$recce->earleme([$number, 0, 1]);
$recce->earleme([$op, "*", 1]);
$recce->earleme([$number, 3, 1]);
$recce->earleme([$op, "+", 1]);
$recce->earleme([$number, 1, 1]);

my @expected = (
    '(((2-0)*3)+1)==7',
    '((2-(0*3))+1)==3',
    '((2-0)*(3+1))==8',
    '(2-((0*3)+1))==1',
    '(2-(0*(3+1)))==2',
);
my $evaler = new Parse::Marpa::Evaluator($recce);
die("Parse failed") unless $evaler;

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

__DATA__
semantics are perl5.  version is 0.205.4.

start symbol is E.

	E: E, Op, E.
q{
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
}.

E: Number.
q{
           my $v0 = pop @$_;
           $v0 . "==" . $v0;
}.

Number matches qr/\d+/.

Op matches qr/[-+*]/.
 
the default action is q{
         my $v_count = scalar @$_;
         return "" if $v_count <= 0;
         return $_->[0] if $v_count == 1;
         "(" . join(";", @$_) . ")";
    }.
