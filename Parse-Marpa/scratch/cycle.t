# An grammars with cycles

use 5.010_000;
use strict;
use warnings;
use lib "../lib";
use English qw( -no_match_vars );
use Fatal qw(open close chdir);

use Test::More tests => 7;

BEGIN {
    use_ok('Parse::Marpa');
}

my $example_dir = "example";
$example_dir = "../example" unless -d $example_dir;
chdir($example_dir);

my $mdl_header = <<'EOF';
semantics are perl5.  version is 0.215.1.
start symbol is S.
default action is q{join(q{ }, @_)}.

EOF

my $cycle1_mdl = $mdl_header . <<'EOF';
S: S.

S matches /./.

EOF

my $cycle2_mdl = $mdl_header . <<'EOF';
S: A.

A: S.

A matches /./.

EOF

my $cycle8_mdl = $mdl_header . <<'EOF';
S: A.

A: B, T, U.

B: V, C.

C: W, D, X.

D: E.

E: S.

E matches /./.

T matches /./.

T: .

U matches /./.

U: .

V matches /./.

V: .

W matches /./.

W: .

X matches /./.

X: .

EOF

for my $test_data (
  [ 
      \$cycle1_mdl,
      \('1'),
      '1',
      <<'EOS'
Cycle found involving rule: 0: s -> s
EOS
  ],
  [
      \$cycle2_mdl,
      \('1'),
      '1',
      <<'EOS'
Cycle found involving rule: 1: a -> s
Cycle found involving rule: 0: s -> a
EOS
  ],
  [
      \$cycle8_mdl,
      \('123456'),
      '1 2 3 4 5 6',
      <<'EOS'
Cycle found involving rule: 3: c -> w d x /* !useful */
Cycle found involving rule: 2: b -> v c /* !useful */
Cycle found involving rule: 1: a -> b t u /* !useful */
Cycle found involving rule: 5: e -> s
Cycle found involving rule: 4: d -> e
Cycle found involving rule: 0: s -> a
EOS
    ],
) {
    my ($grammar, $input, $expected, $expected_trace) = @{$test_data};
    my $trace;
    our $MEMORY;
    open(MEMORY, '>', \$trace);
    my $value = Parse::Marpa::mdl(
        $grammar,
        $input,
        {
            cycle_action => 'warn',
            trace_file_handle => *MEMORY,
        }
    );
    is($$value, $expected);
    is($trace, $expected_trace);
}

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
