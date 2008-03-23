use 5.010_000;
use strict;
use warnings;
use English;
use Parse::Marpa;

my @tests = split(/\n/, <<'EO_TESTS');
time  / 25 ; # / ; die "this dies!";
sin  / 25 ; # / ; die "this dies!";
caller  / 25 ; # / ; die "this dies!";
eof  / 25 ; # / ; die "this dies!";
localtime  / 25 ; # / ; die "this dies!";
EO_TESTS

my $source; { local($RS) = undef; $source = <DATA> };

my $g = new Parse::Marpa::Grammar( { mdl_source => \$source });

TEST: while (my $test = pop @tests) {
    say "Here's what I'm parsing: ", $test;
    my $recce = new Parse::Marpa::Recognizer({grammar => $g});
    my $exhaustion_location = $recce->text(\$test);
    if ($exhaustion_location >= 0) {
        die("Parse exhausted at location $exhaustion_location in line: $test\n");
    }
    my $evaler = new Parse::Marpa::Evaluator($recce);
    unless ($evaler)
    {
        die("No parse for line: $test\n");
    }
    my @parses;
    while (defined(my $value = $evaler->next)) {
        push(@parses, $value);
    }
    if (scalar @parses == 1) {
       say "Things look good, I've got just one parse:";
       say ${$parses[0]};
       print "\n";
       next TEST;
    }
    say "Things look complicated here, I've got ", scalar @parses, " parses:";
    for (my $i = 0; $i < @parses; $i++) {
        say "Parse $i: ", ${$parses[$i]};
    }
    print "\n";
}

__DATA__
semantics are perl5.  version is 0.205.0.  the start symbol is perl line.
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
