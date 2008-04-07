use 5.010_000;
use strict;
use warnings;
use lib "../lib";
use English;

use Test::More tests => 5;

BEGIN {
    use_ok( 'Parse::Marpa' );
}

my @tests = split(/\n/, <<'EO_TESTS');
time  / 25 ; # / ; die "this dies!";
sin  / 25 ; # / ; die "this dies!";
EO_TESTS

# my @tests = split(/\n/, <<'EO_TESTS');
# time  / 25 ; # / ; die "this dies!";
# sin  / 25 ; # / ; die "this dies!";
# caller  / 25 ; # / ; die "this dies!";
# eof  / 25 ; # / ; die "this dies!";
# localtime  / 25 ; # / ; die "this dies!";
# EO_TESTS

my $source; { local($RS) = undef; $source = <DATA> };

my $g = new Parse::Marpa::Grammar({
    warnings => 1,
    code_lines => -1,
});

$g->set({ mdl_source => \$source });

$g->precompute();

TEST: while (my $test = pop @tests) {
    my $recce = new Parse::Marpa::Recognizer({grammar => $g});
    $recce->text(\$test);
    my $evaler = new Parse::Marpa::Evaluator($recce);
    my @parses;
    while (defined(my $value = $evaler->next)) {
        push(@parses, $value);
    }
    my @expected_parses;
    my ($test_name) = ($test =~ /^([a-z]+) /);
    given($test_name) {
        when("time") {
	    @expected_parses = (
		"division, comment"
	    );
	}
        when("sin") {
	    @expected_parses = (
		"division, comment",
		"sin function call, die statement",
	    );
	}
	default {
	    croak("unexpected test: $test_name");
	}
    }
    my $expected_parse_count = scalar @expected_parses;
    my $parse_count = scalar @parses;
    is($parse_count, $expected_parse_count, "Parse count for $test_name is $parse_count");
    my $mismatch_count = 0;
    for (my $i = 0; $i < $parse_count && $i < $expected_parse_count; $i++) {
         if (${$parses[$i]} ne $expected_parses[$i]) {
	     diag(
		 "Mismatch on parse $i for test $test_name: "
		 . ${$parses[$i]}
		 . " vs. "
		 . $expected_parses[$i]
	     );
	     $mismatch_count++;
	 }
    }
    ok(!$mismatch_count,
	($expected_parse_count-$mismatch_count)
	    . " of the $expected_parse_count parses expected succeeded"
    );
}

__DATA__
semantics are perl5.  version is 0.207.1.  the start symbol is perl line.
the default lex prefix is qr/\s*/.

perl line: perl statements, optional comment.
q{
    my $result = $_->[0];
    $result .= ", comment"
	if defined $_->[1];
    $result
}.

perl statements: semicolon separated perl statement sequence.
q{ join(", ", @{$_}) }.

perl statement: division. q{ "division" }.

perl statement: function call.
q{ $_->[0] }.

perl statement: empty statement.  q{ "empty statement" }.

perl statement: /die/, string literal.  q{ "die statement" }.

division: expr, division sign, expr.

expr: function call.

expr: number.

function call: unary function name, argument.
q{ $_->[0] . " function call" }.

function call: nullary function name.
q{ $_->[0] . " function call" }.

argument: pattern match.

empty statement: horizontal whitespace.

horizontal whitespace matches qr/ \t/.

unary function name matches /(caller|eof|sin|localtime)/.

nullary function name matches /(caller|eof|sin|time|localtime)/.

number matches /\d+/.

semicolon matches /;/.

division sign matches qr{/}.

pattern match matches qr{/[^/]*/}.

comment matches /#.*/.

string literal matches qr{"[^"]*"}.
