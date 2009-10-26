#!perl
# Two rules which start with nullables, and cycle.

use 5.010;
use strict;
use warnings;

use Test::More tests => 7;

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
    return $vals[0] if $v_count == 1;
    return '(' . join( q{;}, @vals ) . ')';
} ## end sub default_action

## use critic

my $grammar = Marpa::Grammar->new(
    {   start   => 'S',
        strip   => 0,
        maximal => 1,
        cycle_scale => 4,

        rules => [
            [ 'S', [qw/p p p n/], ],
            [ 'p', ['a'], ],
            [ 'p', [], ],
            [ 'n', ['a'], ],
            [ 'n', ['r2'], ],
            [ 'r2', [qw/a b c d e x/], ],
            [ 'a', [] ],
            [ 'b', [] ],
            [ 'c', [] ],
            [ 'd', [] ],
            [ 'e', [] ],
            [ 'a', ['a'] ],
            [ 'b', ['a'] ],
            [ 'c', ['a'] ],
            [ 'd', ['a'] ],
            [ 'e', ['a'] ],
            [ 'x', ['S'], ],
        ],
        terminals      => ['a'],
        maximal => 1,
        default_action => 'main::default_action',
    }
);

$grammar->precompute();

my @results = qw{NA (-;-;-;a) (a;-;-;a) (a;a;-;a) (a;a;a;a)};

for my $input_length ( 1 .. 8 ) {
    my $recce = Marpa::Recognizer->new( { grammar => $grammar } );
    TOKEN: for my $token ( 1 .. $input_length ) {
        next TOKEN if $recce->earleme( [ 'a', 'a', 1 ] );
        Marpa::exception( 'Parsing exhausted at character: ', $token );
    }
    $recce->end_input();
    my $evaler = Marpa::Evaluator->new( { recce => $recce, clone => 0 } );
    my $i = 0;
    while (my $value = $evaler->value() and $i++ < 3) {
    Marpa::Test::is( ${$value}, $results[$input_length],
        "cycle with initial nullables, input length=$input_length, pass $i" );
    }
} ## end for my $input_length ( 1 .. 4 )

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
