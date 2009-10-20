#!perl
# Two rules which start with nullables, and cycle.

use 5.010;
use strict;
use warnings;

use Smart::Comments '-ENV';

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
        trace_values => 4,

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
            [ 'x', ['S'], ],
        ],
        terminals      => ['t'],
        maximal => 1,
        default_action => 'main::default_action',
    }
);

$grammar->precompute();

my $a = $grammar->get_terminal('t');

my @results = qw{NA (-;-;-;a) (a;-;-;a) (a;a;-;a) (a;a;a;a)};

for my $input_length ( 1 .. 8 ) {
    my $recce = Marpa::Recognizer->new( { grammar => $grammar } );
    TOKEN: for my $token ( 1 .. $input_length ) {
        next TOKEN if $recce->earleme( [ $a, 'a', 1 ] );
        Marpa::exception( 'Parsing exhausted at character: ', $token );
    }
    $recce->end_input();
    ### <where>
    ### trace_fh: $grammar->[Marpa'Internal'Grammar'TRACE_FILE_HANDLE]
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
