#!perl

# A grammars with cycles
use 5.010;
use strict;
use warnings;
use lib 'lib';
use English qw( -no_match_vars );
use Fatal qw(open close chdir);
use Test::More tests => 4;
use t::lib::Marpa::Test;

BEGIN {
    Test::More::use_ok('Marpa');
}

my $example_dir = 'example';
chdir $example_dir;

my @expected_values = split /\n/xms, <<'EOS';
A(B(a))
a
EOS

## no critic (Subroutines::RequireArgUnpacking)
sub show_A         { return 'A(' . $_[0] . ')' }
sub show_B         { return 'B(' . $_[0] . ')' }
sub default_action { join( q{ }, @_ ) }
## use critic

my $mdl = <<'EOF';
semantics are perl5.  version is 0.001_019.
start symbol is S.
default action is 'main::default_action'.

S: A.

A: B. 'main::show_A'.

A: /a/.

B: A. 'main::show_B'.
EOF

my $trace;
open my $MEMORY, '>', \$trace;
my $grammar = Marpa::Grammar->new(
    {   mdl_source        => \$mdl,
        trace_file_handle => $MEMORY,
    }
);
$grammar->precompute();
close $MEMORY;

Marpa::Test::is( $trace, <<'EOS', 'cycle detection' );
Cycle found involving rule: 3: b -> a
Cycle found involving rule: 1: a -> b
EOS

my $recce = Marpa::Recognizer->new(
    {   grammar           => $grammar,
        trace_file_handle => *STDERR,
    }
);

my $text          = 'a';
my $fail_location = $recce->text( \$text );
if ( $fail_location >= 0 ) {
    Marpa::exception(
        Marpa::show_location( 'Parsing failed', \$text, $fail_location ) );
}
$recce->end_input();

my $evaler = Marpa::Evaluator->new( { recce => $recce } );
my $parse_count = 0;
while ( my $value = $evaler->value() ) {
    Marpa::Test::is(
        ${$value},
        $expected_values[$parse_count],
        "cycle depth test $parse_count"
    );
    $parse_count++;
} ## end while ( my $value = $evaler->value() )

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
