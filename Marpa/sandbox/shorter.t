#!perl
# Two rules which start with nullables, and cycle.

use 5.010;
use strict;
use warnings;

use Test::More tests => 7;

use lib 'lib';
use t::lib::Marpa::Test;

BEGIN {
    Test::More::use_ok('Marpa');
}

## no critic (Subroutines::RequireArgUnpacking)

sub default_action {
    shift;
    my $v_count = scalar @_;
    return q{} if $v_count <= 0;
    my @vals = map { $_ // q{-} } @_;
    # return $vals[0] if $v_count == 1;
    return '(' . join( q{;}, @vals ) . ')';
} ## end sub default_action

sub null_a {'a'}
sub null_b {'b'}
sub null_c {'c'}
sub null_d {'d'}
sub null_e {'e'}
sub null_p {'p'}

sub rule_a {
    shift;
    'a(' . ( join ';', map { $_ // '-' } @_ ) . ')';
}

sub rule_b {
    shift;
    'b(' . ( join ';', map { $_ // '-' } @_ ) . ')';
}

sub rule_c {
    shift;
    'c(' . ( join ';', map { $_ // '-' } @_ ) . ')';
}

sub rule_d {
    shift;
    'd(' . ( join ';', map { $_ // '-' } @_ ) . ')';
}

sub rule_e {
    shift;
    'e(' . ( join ';', map { $_ // '-' } @_ ) . ')';
}

sub rule_p {
    shift;
    'p(' . ( join ';', map { $_ // '-' } @_ ) . ')';
}

sub rule_x {
    shift;
    'x(' . ( join ';', map { $_ // '-' } @_ ) . ')';
}

sub rule_S {
    shift;
    'S(' . ( join ';', ( map { $_ // '-' } @_ ) ) . ')';
}

sub rule_n1 {
    shift;
    'n1(' . ( join ';', ( map { $_ // '-' } @_ ) ) . ')';
}

sub rule_n2 {
    shift;
    'n2(' . ( join ';', ( map { $_ // '-' } @_ ) ) . ')';
}

sub rule_r2 {
    shift;
    'r2(' . ( join ';', ( map { $_ // '-' } @_ ) ) . ')';
}

## use critic

my $grammar = Marpa::Grammar->new(
    { experimental => 1 },
    {   start         => 'S',
        strip         => 0,
        maximal       => 1,
        cycle_rewrite => 0,
        cycle_action  => 'warn',
        parse_order   => 'none',

        rules => [
            { lhs => 'S', rhs => [qw/p n/], action => 'main::rule_S' },
            { lhs => 'p', rhs => ['a'],         action => 'main::rule_p' },
            { lhs => 'p', rhs => [],            action => 'main::null_p' },
            { lhs => 'n', rhs => ['a'],         action => 'main::rule_n1' },
            { lhs => 'n', rhs => ['r2'],        action => 'main::rule_n2' },
            {   lhs    => 'r2',
                rhs    => [qw/a x/],
                action => 'main::rule_r2'
            },
            { lhs => 'a', rhs => [],    action => 'main::null_a' },
            { lhs => 'a', rhs => ['a'], action => 'main::rule_a' },
            { lhs => 'x', rhs => ['S'], action => 'main::rule_x' },
            ],
        terminals      => ['a'],
        maximal        => 1,
        default_action => 'main::default_action',
    }
);

$grammar->precompute();

my @results = qw{NA (-;-;-;a) (a;-;-;a) (a;a;-;a) (a;a;a;a)};

# for my $input_length ( 1 .. 8 ) {
for my $input_length ( 1 ) {
    my $recce = Marpa::Recognizer->new( { grammar => $grammar } );
    defined $recce->tokens( [ ( [ 'a', 'A' ] ) x $input_length ] )
        or Marpa::exception( 'Parsing exhausted' );
    my $evaler = Marpa::Evaluator->new( { recce => $recce, clone => 0,
     trace_values=>2
    } );
    say "Bocage:\n", $evaler->show_bocage(4);
    my $i = 0;
    while (my $value = $evaler->value() and $i++ < 2) {
        say "l=$input_length #$i ", ${$value};
        # Marpa::Test::is( ${$value}, $results[$input_length],
            # "cycle with initial nullables, input length=$input_length, pass $i" );
    }
} ## end for my $input_length ( 1 .. 4 )

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
