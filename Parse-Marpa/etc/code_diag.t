#!perl
# Ensure various coding errors are caught

use 5.010_000;
use strict;
use warnings;

use Test::More tests => 8;

use lib 'lib';
use lib 't/lib';
use Marpa::Test;
use Carp;
use English qw( -no_match_vars );

BEGIN {
	use_ok( 'Parse::Marpa' );
}

$::COMPILE_PHASE_WARNING =
<<'EO_CODE';
# this should be a compile phase warning
my $x = 0;
my $x = 1;
my $x = 2;
$x++;
1;
EO_CODE

$::COMPILE_PHASE_FATAL =
<<'EO_CODE';
# this should be a compile phase error
my $x = 0;
$x=;
$x++;
1;
EO_CODE

$::RUN_PHASE_WARNING =
<<'EO_CODE';
# this should be a run phase warning
my $x = 0;
warn "Test Warning 1";
warn "Test Warning 2";
$x++;
1;
EO_CODE

$::RUN_PHASE_ERROR =
<<'EO_CODE';
# this should be a run phase error
my $x = 0;
$x = 711/0;
$x++;
1;
EO_CODE

$::RUN_PHASE_DIE =
<<'EO_CODE';
# this is a call to die()
my $x = 0;
die('test call to die');
$x++;
1;
EO_CODE

# Need also to test null actions
# and lexing routines

# Errors in evaluation of raw grammars?
# in unstringifying grammars?
# in unstringifying recognizers?

$::GOOD_E_OP_ACTION =
<<'EO_CODE';
    my ($right_string, $right_value)
        = ($_[2] =~ /^(.*)==(.*)$/);
    my ($left_string, $left_value)
        = ($_[0] =~ /^(.*)==(.*)$/);
    my $op = $_[1];
    my $value;
    if ($op eq '+') {
       $value = $left_value + $right_value;
    } elsif ($op eq '*') {
       $value = $left_value * $right_value;
    } elsif ($op eq '-') {
       $value = $left_value - $right_value;
    } else {
       croak("Unknown op: $op");
    }
    '(' . $left_string . $op . $right_string . ')==' . $value;
EO_CODE

$::GOOD_E_NUMBER_ACTION =
<<'EOCODE';
           my $v0 = pop @_;
           $v0 . q{==} . $v0;
EOCODE

$::GOOD_DEFAULT_ACTION =
<<'EOCODE';
     my $v_count = scalar @_;
     return q{} if $v_count <= 0;
     return $_[0] if $v_count == 1;
     '(' . join(q{;}, (map { $_ // 'undef' } @_)) . ')';
EOCODE

sub run_test {
    my $args = shift;

    my $E_Op_action = $::GOOD_E_OP_ACTION;
    my $E_Number_action = $::GOOD_E_NUMBER_ACTION;
    my $preamble = q{1};
    my $lex_preamble = q{1};
    my $default_action = $::GOOD_DEFAULT_ACTION;

    while (my ($arg, $value) = each %{$args})
    {
      given(lc $arg) {
        when ('e_op_action') { $E_Op_action = $value }
        when ('e_number_action') { $E_Number_action = $value }
        when ('default_action') { $default_action = $value }
        when ('lex_preamble') { $lex_preamble = $value }
        when ('preamble') { $preamble = $value }
        default { croak("unknown argument to run_test: $arg"); }
      }
    }

    my $grammar = new Parse::Marpa::Grammar({
        start => 'S',
        rules => [
            [ 'S', [qw/E trailer optional_trailer/], ],
            [ 'E', [qw/E Op E/], $E_Op_action, ],
            [ 'E', [qw/Number/], $E_Number_action, ],
            [ 'optional_trailer', [qw/trailer/], ],
            [ 'optional_trailer', [], ],
            [ 'trailer', [qw/Text/], ],
        ],
        terminals => [
            [ 'Number' => { regex => qr/\d+/xms } ],
            [ 'Op' => { regex => qr/[-+*]/xms } ],
            [ 'Text' => { action => 'lex_q_quote' } ],
        ],
        default_action => $default_action,
        preamble => $preamble,
        lex_preamble => $lex_preamble,
        default_lex_prefix => '\s*',
    });

    $grammar->precompute();

    my $recce = new Parse::Marpa::Recognizer({grammar => $grammar});

    my $fail_offset = $recce->text( '2 - 0 * 3 + 1 q{trailer}' );
    if ( $fail_offset >= 0 ) {
        croak("Parse failed at offset $fail_offset");
    }

    $recce->end_input();

    my $expected = '(((2-0)*3)+1)==7';
    my $evaler = new Parse::Marpa::Evaluator( { recce => $recce } );
    my $value = $evaler->value();
    Marpa::Test::is(${$value}, $expected, 'Ambiguous Equation Value');

    return 1;

} # sub run_test

run_test({});

for my $test_code_data (
  [ "compile phase warning", $::COMPILE_PHASE_WARNING, ],
  [ "compile phase fatal", $::COMPILE_PHASE_FATAL, ],
  [ "run phase warning", $::RUN_PHASE_WARNING, ],
  [ "run phase error", $::RUN_PHASE_ERROR, ],
  [ "run phase die", $::RUN_PHASE_DIE, ],
) {
    my ($test_code_name, $test_code) = @{$test_code_data};
    for my $feature (qw(preamble lex_preamble e_op_action default_action))
    {
        my $test_name = "$test_code_name in $feature";
        if (eval {
            run_test({
                $feature => $test_code,
            });
        })
        {
           fail("$test_name did not fail -- that shouldn't happen");
        } else {
            my $eval_error = $EVAL_ERROR;
            Marpa::Test::is($eval_error, q{}, $test_name);
        }
    }
}

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
