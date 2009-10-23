#!perl
# Two rules which start with nullables, and cycle.

use 5.010;
use strict;
use warnings;

use Smart::Comments '-ENV';

use Test::More tests => 25;

use lib 'lib';
use t::lib::Marpa::Test;

BEGIN {
    Test::More::use_ok('Marpa');
}

## no critic (Subroutines::RequireArgUnpacking)

sub default_action {
    shift;
    my $v_count = scalar @_;
    return q{} if $v_count <= 0;
    my @vals = map { $_ // q{-} } @_;
    return $_[0] if scalar @vals == 1;
    return '(' . join( q{;}, @vals ) . ')';
} ## end sub default_action

## use critic

my $grammar = Marpa::Grammar->new(
    {   start   => 'S',
        strip   => 0,
        maximal => 1,

        rules => [
            [ 'S', [qw/p p p n/], ],
            [ 'p', ['t'], ],
            [ 'p', [], ],
            [ 'n', ['t'], ],
            [ 'n', ['r2'], ],
            [ 'r2', [qw/a b c d e x/], ],
            [ 'a', [] ],
            [ 'b', [] ],
            [ 'c', [] ],
            [ 'd', [] ],
            [ 'e', [] ],
            [ 'a', ['t'] ],
            [ 'b', ['t'] ],
            [ 'c', ['t'] ],
            [ 'd', ['t'] ],
            [ 'e', ['t'] ],
            [ 'x', ['t'], ],
        ],
        terminals      => ['t'],
        maximal => 1,
        default_action => 'main::default_action',
    }
);

$grammar->precompute();

my $a = $grammar->get_terminal('t');

my @results;
$results[1][0] = '(-;-;-;(-;-;-;-;-;a))';
$results[1][1] = '(-;-;-;a)';
$results[2][0] = '(a;-;-;(-;-;-;-;-;a))';
$results[2][1] = '(a;-;-;a)';
$results[2][2] = '(-;a;-;(-;-;-;-;-;a))';
$results[3][0] = '(a;a;-;(-;-;-;-;-;a))';
$results[3][1] = '(a;a;-;a)';
$results[3][2] = '(a;-;a;(-;-;-;-;-;a))';
$results[4][0] = '(a;a;a;(-;-;-;-;-;a))';
$results[4][1] = '(a;a;a;a)';
$results[4][2] = '(a;a;-;(a;-;-;-;-;a))';
$results[5][0] = '(a;a;a;(a;-;-;-;-;a))';
$results[5][1] = '(a;a;a;(-;a;-;-;-;a))';
$results[5][2] = '(a;a;a;(-;-;a;-;-;a))';
$results[6][0] = '(a;a;a;(a;a;-;-;-;a))';
$results[6][1] = '(a;a;a;(a;-;a;-;-;a))';
$results[6][2] = '(a;a;a;(a;-;-;a;-;a))';
$results[7][0] = '(a;a;a;(a;a;a;-;-;a))';
$results[7][1] = '(a;a;a;(a;a;-;a;-;a))';
$results[7][2] = '(a;a;a;(a;a;-;-;a;a))';
$results[8][0] = '(a;a;a;(a;a;a;a;-;a))';
$results[8][1] = '(a;a;a;(a;a;a;-;a;a))';
$results[8][2] = '(a;a;a;(a;a;-;a;a;a))';
$results[9][0] = '(a;a;a;(a;a;a;a;a;a))';

for my $input_length ( 1 .. 9 ) {
    my $recce = Marpa::Recognizer->new( { grammar => $grammar } );
    TOKEN: for my $token ( 1 .. $input_length ) {
        next TOKEN if $recce->earleme( [ $a, 'a', 1 ] );
        Marpa::exception( 'Parsing exhausted at character: ', $token );
    }
    $recce->end_input();
    my $evaler = Marpa::Evaluator->new( { recce => $recce, clone => 0 } );
    my $i = 0;
    while ( $i < 3 and my $value = $evaler->value() ) {
        my $expected = $results[$input_length][$i] // q{[unexpected result]};
        Marpa::Test::is( ${$value}, $expected,
            "cycle with initial nullables, input length=$input_length, value #$i"
        );
        $i++;
    } ## end while ( my $value = $evaler->value() and $i < 3 )
} ## end for my $input_length ( 1 .. 9 )

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
