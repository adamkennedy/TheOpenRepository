#!perl

# the example grammar in Aycock/Horspool "Practical Earley Parsing",
# _The Computer Journal_, Vol. 45, No. 6, pp. 620-630,
# in its "NNF" form

use 5.010;
use strict;
use warnings;

use lib 'lib';
use Test::More tests => 20;
use t::lib::Marpa::Test;

BEGIN {
    Test::More::use_ok('Marpa');
}

my $default_action     = <<'END_OF_CODE';
     my $v_count = scalar @_;
     return q{} if $v_count <= 0;
     return $_[0] if $v_count == 1;
     '(' . join(';', @_) . ')';
END_OF_CODE


# Basic tests of sequences.
# The matrix is separation (none/perl5/proper);
# and minimium count (0 or 1);
# keep vs. no-keep.

sub run_sequence_test {
    my ($minimum, $separation, $keep) = @_;

    my @separation_args = $separation eq 'none' ? () : ( separator => 'sep' );
    if ( $separation eq 'proper' ) {
        push @separation_args, proper_separation => 1;
    }
    my $grammar = Marpa::Grammar->new(
        {   precompute => 0,
            start      => 'TOP',
            strip      => 0,
            rules      => [
                {   lhs        => 'TOP',
                    rhs        => [qw/A/],
                    min        => $minimum,
                    keep       => $keep,
                    @separation_args
                },
            ],
            default_action     => $default_action,
            default_null_value => q{},
        }
    );

    $grammar->set( { terminals => [qw(a sep)] } );

    $grammar->precompute();

    my $A = $grammar->get_symbol('A');
    my $sep = $grammar->get_symbol('sep');

    for my $symbol_count ( 0, 1, 2, 3, 5, 10 ) {
        my $recce = Marpa::Recognizer->new( { grammar => $grammar } );

        for my $symbol_ix ( 0 .. $symbol_count ) {
            $recce->earleme( [ $A, 'a', 1 ] )
                or Marpa::exception('Parsing exhausted');
            if (   $separation eq 'proper' and $symbol_ix >= $symbol_count
                or $separation eq 'perl5' )
            {
                $recce->earleme( [ $sep, '!', 1 ] )
                    or Marpa::exception('Parsing exhausted');
            } ## end if ( $separation eq 'proper' and $symbol_ix >= ...)
        } ## end for my $symbol_ix ( 0 .. $symbol_count )

        $recce->end_input();

        my $evaler = Marpa::Evaluator->new(
            {   recce => $recce,
                clone => 0,
            }
        );
        my $result = $evaler->value();
        Test::More::is( ${$result}, q{}, "min=$minimum; keep=$keep; $separation; count=$symbol_count" );

    } ## end for my $symbol_count ( 0, 1, 2, 3, 5, 10 )
} ## end sub run_sequence_test


for my $minimum ( 0, 1 ) {
    for my $separation (qw(none proper perl5)) {
        for my $keep ( 0, 1 ) {
            run_sequence_test( $minimum, $separation, $keep );
        }
    }
} ## end for my $mininum ( 0, 1 )

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
