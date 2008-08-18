# An grammars with cycles

use 5.010_000;
use strict;
use warnings;
use lib "../lib";
use English qw( -no_match_vars );
use Fatal qw(open close chdir);

use Test::More tests => 6;

BEGIN {
    use_ok('Parse::Marpa');
}

my $example_dir = "example";
$example_dir = "../example" unless -d $example_dir;
chdir($example_dir);

my $mdl_header = <<'EOF';
semantics are perl5.  version is 0.215.1.
start symbol is S.
default_action is q{join(q{ }, @_)}.

EOF

my $cycle1_mdl = $mdl_header . <<'EOF';
S: S.

S matches /./.

EOF

my $cycle2_mdl = $mdl_header . <<'EOF';
S: S.

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

U matches /./.

V matches /./.

W matches /./.

X matches /./.

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
Cycle found involving rule: 2: a -> s
Cycle found involving rule: 1: s -> a
Cycle found involving rule: 0: s -> s
EOS
  ],
  [
      \$cycle8_mdl,
      \('123456'),
      '1 2 3 4 5 6',
      <<'EOS'
to do
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
