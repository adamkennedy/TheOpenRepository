#!perl
# Catch the case of a final non-nulling symbol at the end of a rule
# which has more than 2 proper nullables
# This is to test an untested branch of the CHAF logic.

use 5.010;
use strict;
use warnings;

use Test::More tests => 7;

use lib 'lib';
use t::lib::Marpa::Test;

BEGIN {
    Test::More::use_ok('Marpa');
}

my $grammar = Marpa::Grammar->new(
    {   start   => 'S',
        strip   => 0,
        maximal => 1,

        # Set max at 10 just in case there's an infinite loop.
        # This is for debugging, after all
        max_parses => 10,

        rules => [
            [ 'S', [qw/p p p n/], ],
            [ 'p', ['a'], ],
            [ 'p', [], ],
            [ 'n', ['a'], ],
        ],
        terminals => ['a'],

        default_action => <<'EO_CODE',
     my $v_count = scalar @_;
     return q{} if $v_count <= 0;
     my @vals = map { $_ // '-' } @_;
     return $vals[0] if $v_count == 1;
     '(' . join(q{;}, @vals) . ')';
EO_CODE

    }
);

$grammar->precompute();

Marpa::Test::is( $grammar->show_rules,
    <<'END_OF_STRING', 'final nonnulling Rules' );
0: S -> p p p n /* !useful maximal */
1: p -> a /* maximal */
2: p -> /* !useful empty nullable maximal */
3: n -> a /* maximal */
4: S -> p p S[R0:2][x5] /* maximal */
5: S -> p[] p S[R0:2][x5] /* maximal */
6: S -> p p[] S[R0:2][x5] /* maximal */
7: S -> p[] p[] S[R0:2][x5] /* maximal */
8: S[R0:2][x5] -> p n /* maximal */
9: S[R0:2][x5] -> p[] n /* maximal */
10: S['] -> S /* maximal */
END_OF_STRING

Marpa::Test::is( $grammar->show_QDFA,
    <<'END_OF_STRING', 'final nonnulling QDFA' );
Start States: S0; S1
S0: 27
S['] -> . S
 <S> => S2
S1: predict; 1,3,5,10,13,19,21,25
p -> . a
n -> . a
S -> . p p S[R0:2][x5]
S -> p[] . p S[R0:2][x5]
S -> . p p[] S[R0:2][x5]
S -> p[] p[] . S[R0:2][x5]
S[R0:2][x5] -> . p n
S[R0:2][x5] -> p[] . n
 <S[R0:2][x5]> => S3
 <a> => S4
 <n> => S5
 <p> => S6; S7
S2: 28
S['] -> S .
S3: 20
S -> p[] p[] S[R0:2][x5] .
S4: 2,4
p -> a .
n -> a .
S5: 26
S[R0:2][x5] -> p[] n .
S6: 6,11,15,22
S -> p . p S[R0:2][x5]
S -> p[] p . S[R0:2][x5]
S -> p p[] . S[R0:2][x5]
S[R0:2][x5] -> p . n
 <S[R0:2][x5]> => S8
 <n> => S9
 <p> => S10; S7
S7: predict; 1,3,21,25
p -> . a
n -> . a
S[R0:2][x5] -> . p n
S[R0:2][x5] -> p[] . n
 <a> => S4
 <n> => S5
 <p> => S11; S12
S8: 12,16
S -> p[] p S[R0:2][x5] .
S -> p p[] S[R0:2][x5] .
S9: 23
S[R0:2][x5] -> p n .
S10: 7
S -> p p . S[R0:2][x5]
 <S[R0:2][x5]> => S13
S11: 22
S[R0:2][x5] -> p . n
 <n> => S9
S12: predict; 3
n -> . a
 <a> => S14
S13: 8
S -> p p S[R0:2][x5] .
S14: 4
n -> a .
END_OF_STRING

my $a = $grammar->get_symbol('a');

my @results = qw{NA (-;-;-;a) (a;-;-;a) (a;a;-;a) (a;a;a;a)};

for my $input_length ( 1 .. 4 ) {
    my $recce = Marpa::Recognizer->new( { grammar => $grammar } );
    TOKEN: for my $token ( 1 .. $input_length ) {
        next TOKEN if $recce->earleme( [ $a, 'a', 1 ] );
        Marpa::exception( 'Parsing exhausted at character: ', $token );
    }
    $recce->end_input();
    my $evaler = Marpa::Evaluator->new( { recce => $recce, clone => 0 } );
    my $value = $evaler->value();
    Marpa::Test::is( ${$value}, $results[$input_length],
        "final nonnulling, input length=$input_length" );
} ## end for my $input_length ( 1 .. 4 )

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
