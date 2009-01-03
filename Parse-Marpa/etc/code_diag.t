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

BEGIN {
	use_ok( 'Parse::Marpa' );
}

$::COMPILE_PHASE_FATAL =
<<'EO_CODE';
# this should be a compile time fatal error
my $x = 0;
$x++;
!-!%!; $x+=4;
$x--;
$x++;
EO_CODE

# compile phase warning (undeclared variable?)
# run phase die()
# run phase error (divide by zero)
# run phase warn()

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
     '(' . join(q{;}, @_) . ')';
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
        start => 'E',
        strip => 0,
        rules => [
            [ 'E', [qw/E Op E/], $E_Op_action, ],
            [ 'E', [qw/Number/], $E_Number_action, ],
        ],
        terminals => [
            [ 'Number' => { regex => qr/\d+/xms } ],
            [ 'Op' => { regex => qr/[-+*]/xms } ],
        ],
        default_action => $default_action,
        preamble => $preamble,
        lex_preamble => $lex_preamble,
    });

    $grammar->precompute();

    my $recce = new Parse::Marpa::Recognizer({grammar => $grammar});

    my $op = $grammar->get_symbol('Op');
    my $number = $grammar->get_symbol('Number');

    my @tokens = (
        [$number, 2, 1],
        [$op, q{-}, 1],
        [$number, 0, 1],
        [$op, q{*}, 1],
        [$number, 3, 1],
        [$op, q{+}, 1],
        [$number, 1, 1],
    );

    TOKEN: for my $token (@tokens) {
        next TOKEN if $recce->earleme($token);
        croak('Parsing exhausted at character: ', $token->[1]);
    }

    $recce->end_input();

    my $expected = '(((2-0)*3)+1)==7';
    my $evaler = new Parse::Marpa::Evaluator( { recce => $recce } );
    my $value = $evaler->value();
    is(${$value}, $expected, 'Ambiguous Equation Value');

    return 1;

} # sub run_test

run_test({});
run_test({
    preamble => $::COMPILE_PHASE_FATAL
});

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
