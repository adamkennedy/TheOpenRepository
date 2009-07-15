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

sub make_rule {
    my ( $lhs_symbol_name, $rhs_symbol_name ) = @_;
    my $action = q{ '<<LHS>>(' . $_[0] . ')' };
    $action =~ s/<<LHS>>/$lhs_symbol_name/xms;
    return [ $lhs_symbol_name, [$rhs_symbol_name], $action ];
} ## end sub make_rule

sub make_plex_rules {
    my ($size) = @_;
    my @symbol_names = map { 'S' . $_ } ( 0 .. $size-1 );
    my @rules;
    for my $lhs_symbol (@symbol_names) {
        for my $rhs_symbol (@symbol_names) {
            push @rules, make_rule($lhs_symbol, $rhs_symbol);
        }
        push @rules, make_rule($lhs_symbol, 't');
    }
    return \@rules;
}

my $cycle1_test = [
    'cycle plex test 1',
    [ start => 'S0', rules => make_plex_rules(1) ],
    ['S0(t)'],
    <<'EOS'
Cycle found involving rule: 0: S0 -> S0
EOS
];

my @test_data = ( $cycle1_test, );


for my $test_data (@test_data) {
    my ( $test_name, $rules, $expected_values, $expected_trace ) = @{$test_data};
    my $trace = q{};
    open my $MEMORY, '>', \$trace;
    my %args = (
        @{$rules},
        cycle_action      => 'warn',
        trace_file_handle => $MEMORY,
    );
    my $grammar = Marpa::Grammar->new( \%args );
    my $t = $grammar->get_symbol('t');

    close $MEMORY;
    Marpa::Test::is( $trace, $expected_trace );

    my $recce = Marpa::Recognizer->new(
        { grammar => $grammar, trace_file_handle => \*STDERR } );
    $recce->earleme( [ $t, 't', 1 ] ) or Marpa::exception('Parsing exhausted');
    $recce->end_input();
    my $evaler = Marpa::Evaluator->new( { recce => $recce, clone => 0 } );
    if (not defined $evaler) {
        Marpa::exception("Input not recognized");
    }
    $evaler->audit();
    say $evaler->show_bocage(3);
    my $parse_count = 0;

    while ( my $value = $evaler->old_value() ) {
        my $expected_value = $expected_values->[$parse_count] // "extra value returned";
        Marpa::Test::is(
            ${$value},
            $expected_value,
            "$test_name, value $parse_count"
        );
        $parse_count++;
    } ## end while ( my $value = $evaler->old_value() )


} ## end for my $test_data (@test_data)

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
