#!perl
# A grammar with cycles

use 5.010;
use strict;
use warnings;
use English qw( -no_match_vars );
use Fatal qw(open close chdir);

use Test::More tests => 7;
use lib 'lib';
use lib 't/lib';
use Marpa::Test;

BEGIN {
    Test::More::use_ok('Marpa');
}

my $mdl_header = <<'EOF';
semantics are perl5.  version is 0.001_014.
start symbol is S.
default action is q{join(q{ }, grep { defined $_ } @_)}.

EOF

my $plex_grammar = [
     start => 'Root',
     rules => [
         [ 'Root', [ 'Root' ] ],
         [ 'Root', [ 't' ] ],
     ]
];

my $cycle1_test = [
    $plex_grammar,
    \('1'),
    '1',
    <<'EOS'
Cycle found involving rule: 0: Root -> Root
EOS
];

my @test_data = ( $cycle1_test, );


for my $test_data (@test_data) {
    my ( $rules, $input, $expected, $expected_trace ) =
        @{$test_data};
    my $trace = q{};
    open my $MEMORY, '>', \$trace;
    my %args = (
        @{$rules},
        cycle_action      => 'warn',
        trace_file_handle => $MEMORY,
    );
    my $grammar = Marpa::Grammar->new( \%args );
    my $t = $grammar->get_symbol('t');

    my $recce = Marpa::Recognizer->new( { grammar => $grammar } );
    $recce->earleme( [ $t, 't', 1 ] ) or Marpa::exception('Parsing exhausted');
    $recce->end_input();
    my $evaler = Marpa::Evaluator->new( { recce => $recce, clone => 0 } );
    if (not defined $evaler) {
        Marpa::exception("Input not recognized");
    }
    my $parse_count = 0;

    while ( my $value = $evaler->old_value() ) {
        Marpa::Test::is(
            ${$value},
            q{},
            # $expected_values[$parse_count],
            "cycle depth test $parse_count"
        );
        Marpa::Test::is( $trace,     $expected_trace );
        $parse_count++;
    } ## end while ( my $value = $evaler->old_value() )

    close $MEMORY;

} ## end for my $test_data (@test_data)

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
