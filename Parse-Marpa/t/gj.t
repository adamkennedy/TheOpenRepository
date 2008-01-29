use 5.010_000;
use strict;
use warnings;
use lib "../lib";

use Test::More tests => 9;

BEGIN {
	use_ok( 'Parse::Marpa' );
}

# A grammar from Grune & Jacobs, Parsing Techniques: A Practical Guide, pp 206-207.
# The book is available on the web.

my $g = new Parse::Marpa(
    start => "S'",
    rules => [
        [ "S'", [qw/S $/] ],
        [ "S",  [qw/E/] ],
        [ "E",  [qw/E - T/] ],
        [ "E",  [qw/T/] ],
        [ "T",  [qw/n/] ],
        [ "T",  [qw/( E )/] ],
    ],
    academic => 1,
);

$g->set(
    terminals => [
        [ 'n' => { regex => qr/n/ } ],
        [ '$' => { regex => qr/\$/ } ],
        [ ')' => { regex => qr/\)/ } ],
        [ '(' => { regex => qr/\(/ } ],
        [ '-' => { regex => qr/\-/ } ],
    ],
);

$g->precompute();

is($g->show_rules(), <<'EOS', "Grune/Jacobs Rules");
0: S' -> S $
1: S -> E
2: E -> E - T
3: E -> T
4: T -> n
5: T -> ( E )
EOS

is($g->show_symbols(), <<'EOS', "Grune/Jacobs Symbols");
0: S', lhs=[0], rhs=[]
1: S, lhs=[1], rhs=[0]
2: $, lhs=[], rhs=[0] terminal
3: E, lhs=[2 3], rhs=[1 2 5]
4: -, lhs=[], rhs=[2] terminal
5: T, lhs=[4 5], rhs=[2 3]
6: n, lhs=[], rhs=[4] terminal
7: (, lhs=[], rhs=[5] terminal
8: ), lhs=[], rhs=[5] terminal
EOS

is($g->show_nullable_symbols(), "", "Grune/Jacobs Nullable Symbols");
is($g->show_nulling_symbols(), "", "Grune/Jacobs Nulling Symbols");
is($g->show_productive_symbols(), '$ ( ) - E S S\' T n', "Grune/Jacobs Productive Symbols");
is($g->show_accessible_symbols(), '$ ( ) - E S S\' T n', "Grune/Jacobs Accessible Symbols");
is($g->show_NFA(), <<'EOS', "Grune/Jacobs NFA");
S0: /* empty */
 empty => S1
S1: S' ::= . S $
 empty => S4
 <S> => S2
S2: S' ::= S . $
 <$> => S3
S3: S' ::= S $ .
S4: S ::= . E
 empty => S6 S10
 <E> => S5
S5: S ::= E .
S6: E ::= . E - T
 empty => S6 S10
 <E> => S7
S7: E ::= E . - T
 <-> => S8
S8: E ::= E - . T
 empty => S12 S14
 <T> => S9
S9: E ::= E - T .
S10: E ::= . T
 empty => S12 S14
 <T> => S11
S11: E ::= T .
S12: T ::= . n
 <n> => S13
S13: T ::= n .
S14: T ::= . ( E )
 <(> => S15
S15: T ::= ( . E )
 empty => S6 S10
 <E> => S16
S16: T ::= ( E . )
 <)> => S17
S17: T ::= ( E ) .
EOS

is( $g->show_ii_SDFA(), <<'EOS', "Grune/Jacobs SDFA");
St0: 1
S' ::= . S $
 empty => St9 (4,6,10,12,14)
 <S> => St7 (2)
St1: 11
E ::= T .
St2: 12,14
T ::= . n
T ::= . ( E )
 <(> => St4 (15)
 <n> => St3 (13)
St3: 13
T ::= n .
St4: 15
T ::= ( . E )
 empty => St11 (6,10,12,14)
 <E> => St5 (16)
St5: 16
T ::= ( E . )
 <)> => St6 (17)
St6: 17
T ::= ( E ) .
St7: 2
S' ::= S . $
 <$> => St8 (3)
St8: 3
S' ::= S $ .
St9: 4,6,10,12,14
S ::= . E
E ::= . E - T
E ::= . T
T ::= . n
T ::= . ( E )
 <(> => St4 (15)
 <E> => St10 (5,7)
 <T> => St1 (11)
 <n> => St3 (13)
St10: 5,7
S ::= E .
E ::= E . - T
 <-> => St13 (8)
St11: 6,10,12,14
E ::= . E - T
E ::= . T
T ::= . n
T ::= . ( E )
 <(> => St4 (15)
 <E> => St12 (7)
 <T> => St1 (11)
 <n> => St3 (13)
St12: 7
E ::= E . - T
 <-> => St13 (8)
St13: 8
E ::= E - . T
 empty => St2 (12,14)
 <T> => St14 (9)
St14: 9
E ::= E - T .
EOS

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
