#!perl

# the example grammar in Aycock/Horspool "Practical Earley Parsing",
# _The Computer Journal_, Vol. 45, No. 6, pp. 620-630,
# in its "NNF" form

use 5.010;
use strict;
use warnings;
use English qw( -no_match_vars );
use Test::More tests => 6;

use lib 'lib';
use lib 't/lib';
use Marpa::Test;

BEGIN {
    Test::More::use_ok('Marpa');
}

my $default_action = <<'EOCODE';
     my $v_count = scalar @_;
     return q{} if $v_count <= 0;
     return $_[0] if $v_count == 1;
     '(' . join(';', @_) . ')';
EOCODE

sub test_grammar {
    my ($grammar_args, $earleme_length) = @_;
    $earleme_length //= 1;

    my $grammar;
    my $eval_ok = eval { $grammar = Marpa::Grammar->new($grammar_args); 1; };
    Marpa::exception("Exception while creating Grammar:\n$EVAL_ERROR") if not $eval_ok;
    Marpa::exception("Grammar not created\n") if not $grammar;

    my $recce;
    $eval_ok = eval { $recce = Marpa::Recognizer->new( { grammar => $grammar } ); 1; };
    Marpa::exception("Exception while creating Recognizer:\n$EVAL_ERROR") if not $eval_ok;
    Marpa::exception("Recognizer not created\n") if not $recce;
    my $a = $grammar->get_symbol('a');

    my $earleme_result;
    $eval_ok = eval { $earleme_result = $recce->earleme( [ $a, 'a', 1 ] ); 1; };
    Marpa::exception("Exception while recognizing earleme:\n$EVAL_ERROR") if not $eval_ok;
    Marpa::exception("Parsing exhausted\n") if not $earleme_result;

    $eval_ok = eval { $earleme_result = $recce->earleme( [ $a, 'a', $earleme_length ] ); 1; };
    Marpa::exception("Exception while recognizing earleme:\n$EVAL_ERROR") if not $eval_ok;
    Marpa::exception("Parsing exhausted\n") if not $earleme_result;

    $eval_ok = eval { $recce->end_input(); 1; };
    Marpa::exception("Exception while recognizing end of input:\n$EVAL_ERROR") if not $eval_ok;

    my $evaler;
    $eval_ok = eval { $evaler = Marpa::Evaluator->new( { recce => $recce, clone => 0 } ); 1; };
    Marpa::exception("Exception while creating Evaluator:\n$EVAL_ERROR") if not $eval_ok;
    Marpa::exception("Evaluator not created\n") if not $evaler;
    my $value = $evaler->value;
    Marpa::exception("No parse\n") if not $value;
    return ${$value};
} ## end for my $test (@tests)

# RHS too long is not testable
# Perl runs out of memory first

# test a grammar with no limit problems
my $result_on_success = '(a;a)';

my $placebo = {
    start => 'S',
    strip => 0,
    rules => [
        #<<< no perltidy
        [ 'S', [ qw(A A) ] ],
        [ 'A', [qw/a/] ]
        #>>>
    ],
    default_null_value => q{},
    default_action     => $default_action,
};

sub test_rule_priority {
    my ($priority) = @_;
    return {
        start => 'S',
        rules => [
        #<<< no perltidy
        [ 'S', [ qw(A A) ] ],
        [ 'A', [qw/a/], undef, $priority ]
        #>>>
        ],
        default_null_value => q{},
        default_action     => $default_action,
    };
};

my $value;
my $eval_ok = eval { $value = test_grammar($placebo); 1; };
if (not defined $eval_ok) {
    diag($EVAL_ERROR);
    fail('Placebo grammar');
}
else { Test::More::is($value, $result_on_success, 'Placebo grammar') }

$eval_ok = eval { $value = test_grammar( test_rule_priority(1_000_000) ) };
if (not defined $eval_ok) { fail('Priority very high') }
else { Test::More::is($value, $result_on_success, 'Priority very high, but still OK') }

$eval_ok = eval { $value = test_grammar( test_rule_priority(2**31) ) };
REPORT_RESULT: {
    if (defined $eval_ok) {
        fail('Did not catch over-high rule priority');
        last REPORT_RESULT;
    }
    if ($EVAL_ERROR =~ / \A Exception \s while \s creating \s Grammar /xms) {
        pass('Caught over-high rule priority');
        last REPORT_RESULT;
    }
    Test::More::is( $EVAL_ERROR, "Exception while creating Grammar\n", 'Priority too high' );
}

$eval_ok = eval { $value = test_grammar( $placebo, 20031 ); 1; };
if (not defined $eval_ok) { fail('Earleme very long') }
else { Test::More::is($value, $result_on_success, 'Earleme very long, but still OK') }

$eval_ok = eval { $value = test_grammar( $placebo, 2**31 ); 1; };
REPORT_RESULT: {
    if (defined $eval_ok) {
        diag("Earleme too long test returned value: $value");
        fail('Did not catch problem with earleme too long');
        last REPORT_RESULT;
    }
    if ($EVAL_ERROR =~ / \A Exception \s while \s recognizing \s earleme /xms) {
        pass('Caught over-high rule priority');
        last REPORT_RESULT;
    }
    Test::More::is( $EVAL_ERROR, q{}, 'Grammar with earleme too long' );
}

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
