#!perl

# Basic tests of sequences.
# The matrix is separation (none/perl5/proper);
# and minimium count (0, 1, 3);
# keep vs. no-keep.

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

sub run_sequence_test {
    my ($minimum, $separation, $keep) = @_;
    say join ';', @_;

    my @terminals = ('A');
    my @separation_args = ();
    if ($separation ne 'none') {
        push @separation_args, separator => 'sep';
        push @terminals, 'sep';
    }
    if ( $separation eq 'proper' ) {
        push @separation_args, proper => 1;
    }

    my $grammar = Marpa::Grammar->new(
        {   precompute => 0,
            start      => 'TOP',
            trace_lex => 1,
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

    $grammar->set( { terminals => \@terminals } );

    $grammar->precompute();

    say $grammar->show_rules();

    my $A = $grammar->get_symbol('A');
    my $sep = $grammar->get_symbol('sep');

    SYMBOL_COUNT: for my $symbol_count ( 0, 1, 2, 3, 5, 10 ) {
        next SYMBOL_COUNT if $symbol_count < $minimum;
        my $test_name =
              "min=$minimum;"
            . ( $keep ? "keep;" : "" )
            . ( $separation ne 'none' ? "$separation;" : "" )
            . ";count=$symbol_count";
        my $recce = Marpa::Recognizer->new( { grammar => $grammar } );

        my @expected = ();
        my $last_symbol_ix = $symbol_count - 1;
        for my $symbol_ix ( 0 .. $last_symbol_ix ) {
            push @expected, 'a';
            $recce->earleme( [ $A, 'a', 1 ] )
                or Marpa::exception('Parsing exhausted');
            if ($separation ne 'none'
                and (  $symbol_ix <= $last_symbol_ix
                    or $separation eq 'perl5' )
                )
            {
                push @expected, '!';
                $recce->earleme( [ $sep, '!', 1 ] )
                    or Marpa::exception('Parsing exhausted');
            } ## end if ( $separation ne 'proper' and ( $symbol_ix <= ...))
        } ## end for my $symbol_ix ( 0 .. $last_symbol_ix )

        $recce->end_input();

        my $evaler = Marpa::Evaluator->new(
            {   recce => $recce,
                clone => 0,
            }
        );
        if (not $evaler) {
            Test::More::fail("$test_name: Parse failed");
            next SYMBOL_COUNT;
        }
        say $evaler->show_bocage();
        my $result = $evaler->value();

        my $expected = join ';', @expected;
        if (@expected > 1) {
            $expected = "($expected)";
        }
        Test::More::is( ${$result}, $expected, $test_name );

    } ## end for my $symbol_count ( 0, 1, 2, 3, 5, 10 )
} ## end sub run_sequence_test

# for my $minimum ( 0, 1, 3 ) {
for my $minimum ( 0, 1 ) {
    run_sequence_test( $minimum, 'none', 0 );
    for my $separation (qw(proper perl5)) {
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
