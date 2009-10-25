#!perl

# the example grammar in Aycock/Horspool "Practical Earley Parsing",
# _The Computer Journal_, Vol. 45, No. 6, pp. 620-630,
# in its "NNF" form

use 5.010;
use strict;
use warnings;

use lib 'lib';
use Test::More tests => 6;
use t::lib::Marpa::Test;

BEGIN {
    Test::More::use_ok('Marpa');
}

## no critic (Subroutines::RequireArgUnpacking)

sub default_action {
    shift;
    my $v_count = scalar @_;
    return q{}   if $v_count <= 0;
    return $_[0] if $v_count == 1;
    return '(' . join( q{;}, @_ ) . ')';
} ## end sub default_action

## use critic

my $grammar = Marpa::Grammar->new(
    {   start   => 'S',
        strip   => 0,
        minimal => 1,
        rules   => [
            [ 'S', [qw/A A A A/] ],
            [ 'A', [qw/a/] ],
            [ 'A', [qw/E/] ],
            ['E'],
        ],
        default_null_value => q{},
        default_action     => 'main::default_action',
    }
);

$grammar->set( { terminals => ['a'], } );

$grammar->precompute();

my $recce = Marpa::Recognizer->new( { grammar => $grammar, clone => 0 } );

my $input_length = 4;
EARLEME: for my $earleme ( 0 .. $input_length + 1 ) {
    my $furthest = List::Util::min( $earleme, $input_length );
    given ($earleme) {
        when ($input_length) {
            $recce->end_input();
        }
        when ( $input_length + 1 ) {break}
        default {
            my $a = $grammar->get_terminal('a');
            defined $recce->earleme( [ $a, 'a', 1 ] )
                or Marpa::exception('Parsing exhausted');
        }
    } ## end given
} ## end for my $earleme ( 0 .. $input_length + 1 )

my @expected = ( q{}, qw[(;;;a) (;;a;a) (;a;a;a) (a;a;a;a)] );

for my $i ( 0 .. $input_length ) {
    my $evaler = Marpa::Evaluator->new(
        {   recce => $recce,
            end   => $i,
            clone => 0,
        }
    );
    my $result = $evaler->value();
    Test::More::is( ${$result}, $expected[$i], "parse permutation $i" );

} ## end for my $i ( 0 .. $input_length )

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
