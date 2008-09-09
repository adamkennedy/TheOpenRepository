# An grammars with cycles

use 5.010_000;
use strict;
use warnings;
use lib "../lib";
use English qw( -no_match_vars );
use Fatal qw(open close chdir);

use Test::More tests => 24;

BEGIN {
    use_ok('Parse::Marpa');
}

my $example_dir = "example";
$example_dir = "../example" unless -d $example_dir;
chdir($example_dir);

my @expected_values = split("\n", <<'EOS');
a
A(B(a))
A(B(A(B(a))))
A(B(A(B(A(B(a))))))
A(B(A(B(A(B(A(B(a))))))))
A(B(A(B(A(B(A(B(A(B(a))))))))))
A(B(A(B(A(B(A(B(A(B(A(B(a))))))))))))
A(B(A(B(A(B(A(B(A(B(A(B(A(B(a))))))))))))))
A(B(A(B(A(B(A(B(A(B(A(B(A(B(A(B(a))))))))))))))))
A(B(A(B(A(B(A(B(A(B(A(B(A(B(A(B(A(B(a))))))))))))))))))
A(B(A(B(A(B(A(B(A(B(A(B(A(B(A(B(A(B(A(B(a))))))))))))))))))))
EOS

my $mdl = <<'EOF';
semantics are perl5.  version is 0.215.1.
start symbol is S.
default action is q{join(q{ }, @_)}.

S: A.

A: B. q{ 'A(' . $_[0] . ')' }.

A: /a/.

B: A. q{ 'B(' . $_[0] . ')' }.
EOF

my $trace;
our $MEMORY;
open(MEMORY, '>', \$trace);
my $grammar = new Parse::Marpa::Grammar({
    mdl_source => \$mdl,
    trace_file_handle => *MEMORY,
});
$grammar->precompute();

is($trace, <<'EOS');
Cycle found involving rule: 3: b -> a
Cycle found involving rule: 1: a -> b
EOS

my $recce = new Parse::Marpa::Recognizer({
   grammar => $grammar,
   trace_file_handle => *STDERR,
});

my $text = 'a';
my $fail_location = $recce->text( \$text );
if ( $fail_location >= 0 ) {
    croak( Parse::Marpa::show_location( "Parsing failed",
        \$text, $fail_location ) );
}

for my $depth (1, 2, 5, 10) {

    my $evaler = new Parse::Marpa::Evaluator($recce);
    $evaler->set( { cycle_depth => $depth } );
    my $parse_count = 0;
    while (my $value = $evaler->value()) {
        is($$value, $expected_values[$parse_count++]);
    }

}

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
