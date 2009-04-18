#!perl
#
use 5.010;
use strict;
use warnings;
use lib 'lib';
use lib 't/lib';

# The Wall Series: a sequence of numbers generated by an especially
# ambiguous section of Perl syntax, relaxed to ignore precedence
# and lvalue restricitons.

# This produces numbers in the series A052952 in the literature.
# It's a kind of ragtime Fibonacci series.  My proof that the
# parse counts generated by this grammar and A052952 are identical
# is at perlmonks.org: http://perlmonks.org/?node_id=649892

use Test::More tests => 13;

BEGIN {
    Test::More::use_ok('Marpa');
}

use Marpa::Test;

# The inefficiency (at least some of it) is deliberate.
# Passing up a duples of [ string, value ] and then
# assembling a final string at the top would be better
# than assembling the string then taking it
# apart at each step.  But I wanted to test having
# a start symbol that appears repeatedly on the RHS.

my $g = Marpa::Grammar->new(
    {   start => 'E',

        # Set max_parses just in case there's an infinite loop.
        # This is for debugging, after all
        max_parses => 300,

        rules => [
            [   'E', [qw/E Minus E/],
                <<'EOCODE'
    my ($right_string, $right_value)
        = ($_[2] =~ /^(.*)==(.*)$/);
    my ($left_string, $left_value)
        = ($_[0] =~ /^(.*)==(.*)$/);
    my $value = $left_value - $right_value;
    "(" . $left_string . "-" . $right_string . ")==" . $value;
EOCODE
            ],
            [   'E', [qw/E Minus Minus/],
                <<'EOCODE'
    my ($string, $value)
        = ($_[0] =~ /^(.*)==(.*)$/);
    "(" . $string . "--" . ")==" . $value--;
EOCODE
            ],
            [   'E', [qw/Minus Minus E/],
                <<'EOCODE'
    my ($string, $value)
        = ($_[2] =~ /^(.*)==(.*)$/);
    "(" . "--" . $string . ")==" . --$value;
EOCODE
            ],
            [   'E', [qw/Minus E/],
                <<'EOCODE'
    my ($string, $value)
        = ($_[1] =~ /^(.*)==(.*)$/);
    "(" . "-" . $string . ")==" . -$value;
EOCODE
            ],
            [   'E', [qw/Number/],
                <<'EOCODE'
            my $value = $_[0];
            "$value==$value";
EOCODE
            ],
        ],
        default_action => <<'EOCODE'
     my $v_count = scalar @_;
     return "" if $v_count <= 0;
     return $_[0] if $v_count == 1;
     "(" . join(";", @_) . ")";
EOCODE
    }
);

my @expected = qw(0 1 1 3 4 8 12 21 33 55 88 144 232 );

for my $n ( 1 .. 12 ) {

    my $recce  = Marpa::Recognizer->new( { grammar => $g } );
    my $minus  = $g->get_symbol('Minus');
    my $number = $g->get_symbol('Number');
    $recce->earleme( [ $number, 6, 1 ] );
    for my $i ( 1 .. $n ) {
        $recce->earleme( [ $minus, q{-}, 1 ] );
    }
    $recce->earleme( [ $number, 1, 1 ] );
    $recce->end_input();

    my $evaler = Marpa::Evaluator->new( { recce => $recce } );

    my $parse_count = 0;
    while ( $evaler->value() ) { $parse_count++; }
    Marpa::Test::is( $expected[$n], $parse_count, "Wall Series Number $n" );

} ## end for my $n ( 1 .. 12 )

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
