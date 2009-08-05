#!perl

# Test of deletion of duplicate parses.
# Make this part of standard testiing?

use 5.010;
use strict;
use warnings;

use Test::More tests => 4;

use lib 'lib';
use lib 't/lib';
use Marpa::Test;

BEGIN {
    Test::More::use_ok('Marpa');
}

my $grammar = Marpa::Grammar->new(
    {   start => 'S',
        strip => 0,

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
0: S -> p p p n /* !useful */
1: p -> a
2: p -> /* !useful empty nullable nulling */
3: n -> a
4: S -> p p S[R0:2][x5] /* priority=0.44 */
5: S -> p[] p S[R0:2][x5] /* priority=0.42 */
6: S -> p p[] S[R0:2][x5] /* priority=0.43 */
7: S -> p[] p[] S[R0:2][x5] /* priority=0.41 */
8: S[R0:2][x5] -> p n /* priority=0.24 */
9: S[R0:2][x5] -> p[] n /* priority=0.22 */
10: S['] -> S
END_OF_STRING

Marpa::Test::is( $grammar->show_QDFA,
    <<'END_OF_STRING', 'final nonnulling QDFA' );
Start States: S0; S1
S0: 27
S['] ::= . S
 <S> => S2
S1: predict; 1,3,5,10,13,19,21,25
p ::= . a
n ::= . a
S ::= . p p S[R0:2][x5]
S ::= p[] . p S[R0:2][x5]
S ::= . p p[] S[R0:2][x5]
S ::= p[] p[] . S[R0:2][x5]
S[R0:2][x5] ::= . p n
S[R0:2][x5] ::= p[] . n
 <S[R0:2][x5]> => S3
 <a> => S4
 <n> => S5
 <p> => S6; S7
S2: 28
S['] ::= S .
S3: 20
S ::= p[] p[] S[R0:2][x5] .
S4: 2,4
p ::= a .
n ::= a .
S5: 26
S[R0:2][x5] ::= p[] n .
S6: 6,11,15,22
S ::= p . p S[R0:2][x5]
S ::= p[] p . S[R0:2][x5]
S ::= p p[] . S[R0:2][x5]
S[R0:2][x5] ::= p . n
 <S[R0:2][x5]> => S8
 <n> => S9
 <p> => S10; S7
S7: predict; 1,3,21,25
p ::= . a
n ::= . a
S[R0:2][x5] ::= . p n
S[R0:2][x5] ::= p[] . n
 <a> => S4
 <n> => S5
 <p> => S11; S12
S8: 12,16
S ::= p[] p S[R0:2][x5] .
S ::= p p[] S[R0:2][x5] .
S9: 23
S[R0:2][x5] ::= p n .
S10: 7
S ::= p p . S[R0:2][x5]
 <S[R0:2][x5]> => S13
S11: 22
S[R0:2][x5] ::= p . n
 <n> => S9
S12: predict; 3
n ::= . a
 <a> => S14
S13: 8
S ::= p p S[R0:2][x5] .
S14: 4
n ::= a .
END_OF_STRING

my $a = $grammar->get_symbol('a');

my $input_length = 3;
my $recce = Marpa::Recognizer->new( { grammar => $grammar } );
TOKEN: for my $token ( 1 .. $input_length ) {
    next TOKEN if $recce->earleme( [ $a, chr( 0x60 + $token ), 1 ] );
    Marpa::exception( 'Parsing exhausted at character: ', $token );
}
$recce->end_input();
my $evaler = Marpa::Evaluator->new( { recce => $recce, clone => 0 } );

my $bocage =  $evaler->show_bocage(99);
Marpa::Test::is($bocage, <<'END_OF_STRING', 'Bocage');
package: Marpa::E_0; parse count: 0
S2@0-3L6#0 ::= S2@0-3L6#0[0]#0
S2@0-3L6#0[0]#0 ::= S13@0-3L1#1
    rule 10: S['] ::= S .
    rhs length = 1; closure
S2@0-3L6#0 ::= S2@0-3L6#0[1]#1
S2@0-3L6#0[1]#1 ::= S8@0-3L1#2
    rule 10: S['] ::= S .
    rhs length = 1; closure
S13@0-3L1#1 ::= S13@0-3L1#1[0]#2
S13@0-3L1#1[0]#2 ::= S10@0-2R4:2#3 S5@2-3L5#4
    rule 4: (part of 0) S -> { p p } p n .
    rhs length = 3; closure
S8@0-3L1#2 ::= S8@0-3L1#2[0]#3
S8@0-3L1#2[0]#3 ::= S6@0-1R5:2#5 S9@1-3L5#6
    rule 5: (part of 0) S -> { p p } p n .
    rhs length = 3; closure
S8@0-3L1#2 ::= S8@0-3L1#2[1]#4
S8@0-3L1#2[1]#4 ::= S6@0-1R6:2#7 S9@1-3L5#6
    rule 6: (part of 0) S -> { p p } p n .
    rhs length = 3; closure
S10@0-2R4:2#3 ::= S10@0-2R4:2#3[0]#5
S10@0-2R4:2#3[0]#5 ::= S6@0-1R4:1#8 S4@1-2L2#9
    rule 4: (part of 0) S -> { p p . } p n
    rhs length = 3
S5@2-3L5#4 ::= S5@2-3L5#4[0]#7
S5@2-3L5#4[1]#7 ::= S7@2-2R9:1#10 S14@2-3L3#12
    rule 9: (part of 0) S -> p p { p n . }
    rhs length = 2; closure
S6@0-1R5:2#5 ::= S6@0-1R5:2#5[0]#8
S6@0-1R5:2#5[0]#8 ::= S1@0-0R5:1#13 S4@0-1L2#14
    rule 5: (part of 0) S -> { p p . } p n
    rhs length = 3
S9@1-3L5#6 ::= S9@1-3L5#6[0]#10
S9@1-3L5#6[1]#10 ::= S11@1-2R8:1#15 S14@2-3L3#12
    rule 8: (part of 0) S -> p p { p n . }
    rhs length = 2; closure
S6@0-1R6:2#7 ::= S6@0-1R6:2#7[0]#11
S6@0-1R6:2#7[0]#11 ::= S6@0-1R6:1#16 undef
    rule 6: (part of 0) S -> { p p . } p n
    rhs length = 3
S6@0-1R4:1#8 ::= S6@0-1R4:1#8[0]#12
S6@0-1R4:1#8[0]#12 ::= S4@0-1L2#14
    rule 4: (part of 0) S -> { p . p } p n
    rhs length = 3
S4@1-2L2#9 ::= S4@1-2L2#9[0]#13
S4@1-2L2#9[0]#13 ::= 'b'
    rule 1: p ::= a .
    rhs length = 1; closure
S7@2-2R9:1#10 ::= S7@2-2R9:1#10[0]#14
S7@2-2R9:1#10[0]#14 ::= undef
    rule 9: (part of 0) S -> p p { p . n }
    rhs length = 2
S14@2-3L3#12 ::= S14@2-3L3#12[0]#16
S14@2-3L3#12[0]#16 ::= 'c'
    rule 3: n ::= a .
    rhs length = 1; closure
S1@0-0R5:1#13 ::= S1@0-0R5:1#13[0]#17
S1@0-0R5:1#13[0]#17 ::= undef
    rule 5: (part of 0) S -> { p . p } p n
    rhs length = 3
S4@0-1L2#14 ::= S4@0-1L2#14[0]#18
S4@0-1L2#14[0]#18 ::= 'a'
    rule 1: p ::= a .
    rhs length = 1; closure
S11@1-2R8:1#15 ::= S11@1-2R8:1#15[0]#19
S11@1-2R8:1#15[0]#19 ::= S4@1-2L2#9
    rule 8: (part of 0) S -> p p { p . n }
    rhs length = 2
S6@0-1R6:1#16 ::= S6@0-1R6:1#16[0]#20
S6@0-1R6:1#16[0]#20 ::= S4@0-1L2#14
    rule 6: (part of 0) S -> { p . p } p n
    rhs length = 3
END_OF_STRING

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
