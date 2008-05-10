use 5.010_000;
use strict;
use warnings;

# A test of priorities.
# Since it's a basic functionality,
# I bypass MDL.

use lib "../lib";

use Test::More tests => 5;

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
    start => "S",

    # Set max_parses to 20 in case there's an infinite loop.
    # This is for debugging, after all
    max_parses => 20,
    rules => [
	[ 'S', ['P300'], '300', 300 ],
	[ 'S', ['P200'], '200', 200 ],
	[ 'S', ['P400'], '400', 400 ],
	[ 'S', ['P100'], '100', 100 ],
    ],
    terminals => [
	[ 'P200' => { regex => qr/a/ } ],
	[ 'P400' => { regex => qr/a/ } ],
	[ 'P100' => { regex => qr/a/ } ],
	[ 'P300' => { regex => qr/a/ } ],
    ],
});

my $recce = new Parse::Marpa::Recognizer({
    grammar => $g,
});

my @expected = qw(400 300 200 100);

my $fail_offset = $recce->text(\('a'));
if ($fail_offset >= 0) {
   die("Parse failed at offset $fail_offset");
}

my $evaler = new Parse::Marpa::Evaluator($recce);
die("Could not initialize parse") unless $evaler;

for (my $i = 0; defined(my $value = $evaler->value()); $i++) {
    if ($i > $#expected) {
       fail("Minuses equation has extra value: " . $$value . "\n");
    } else {
        is($$value, $expected[$i], "Priority Value $i");
    }
}

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
