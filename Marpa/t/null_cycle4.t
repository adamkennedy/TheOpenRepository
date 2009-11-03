#!perl
# Two rules which start with nullables, and cycle.

use 5.010;
use strict;
use warnings;

use Test::More tests => 13;

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

sub rule_z {
    shift;
    'z(' . ( join ';', map { $_ // '-' } @_ ) . ')';
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
    { experimental => 'no warning' },
    {   start         => 'S',
        strip         => 0,
        maximal       => 1,
        cycle_rewrite => 0,
        cycle_action  => 'quiet',
        parse_order   => 'none',

        rules => [
            { lhs => 'S', rhs => [qw/p p p n/], action => 'main::rule_S' },
            { lhs => 'p', rhs => ['a'],         action => 'main::rule_p' },
            { lhs => 'p', rhs => [],            action => 'main::null_p' },
            { lhs => 'n', rhs => ['a'],         action => 'main::rule_n1' },
            { lhs => 'n', rhs => ['r2'],        action => 'main::rule_n2' },
            {   lhs    => 'r2',
                rhs    => [qw/a b c d e z/],
                action => 'main::rule_r2'
            },
            { lhs => 'a', rhs => [],    action => 'main::null_a' },
            { lhs => 'b', rhs => [],    action => 'main::null_b' },
            { lhs => 'c', rhs => [],    action => 'main::null_c' },
            { lhs => 'd', rhs => [],    action => 'main::null_d' },
            { lhs => 'e', rhs => [],    action => 'main::null_e' },
            { lhs => 'a', rhs => ['a'], action => 'main::rule_a' },
            { lhs => 'b', rhs => ['a'], action => 'main::rule_b' },
            { lhs => 'c', rhs => ['a'], action => 'main::rule_c' },
            { lhs => 'd', rhs => ['a'], action => 'main::rule_d' },
            { lhs => 'e', rhs => ['a'], action => 'main::rule_e' },
            { lhs => 'z', rhs => ['S'], action => 'main::rule_z' },
            ],
        terminals      => ['a'],
        maximal        => 1,
        default_action => 'main::default_action',
    }
);

$grammar->precompute();

my @results;
$results[1] = [
    qw{
        S(p;p;p;n2(r2(a;b;c;d;e;z(S(p(a(A));p;p;-)))))
        S(p;p;p;n2(r2(a;b;c;d;e;z(S(p(A);p;p;-)))))
        S(p;p;p;n2(r2(a;b;c;d;e(a(A));-)))
        S(p;p;p;n2(r2(a;b;c;d;e(A);-)))
        }
];

$results[2] = [
    qw{
        S(p;p;p;n2(r2(a;b;c;d;e;z(S(p(a(A));p;p;n2(r2(a;b;c;d;e;z(S(p;p(a(A));p;-)))))))))
        S(p;p;p;n2(r2(a;b;c;d;e;z(S(p(a(A));p;p;n2(r2(a;b;c;d;e;z(S(p;p(A);p;-)))))))))
        S(p;p;p;n2(r2(a;b;c;d;e;z(S(p(a(A));p;p;n2(r2(a;b;c;d;e;z(S(p(a(A));p;p;-)))))))))
        S(p;p;p;n2(r2(a;b;c;d;e;z(S(p(a(A));p;p;n2(r2(a;b;c;d;e;z(S(p(A);p;p;-)))))))))
        }
];

$results[3] = [
    qw{
        S(p;p;p;n2(r2(a;b;c;d;e;z(S(p(a(A));p;p;n2(r2(a;b;c;d;e;z(S(p;p(a(A));p;n2(r2(a;b;c;d;e;z(S(p;p;p(a(A));-)))))))))))))
        S(p;p;p;n2(r2(a;b;c;d;e;z(S(p(a(A));p;p;n2(r2(a;b;c;d;e;z(S(p;p(a(A));p;n2(r2(a;b;c;d;e;z(S(p;p;p(A);-)))))))))))))
        S(p;p;p;n2(r2(a;b;c;d;e;z(S(p(a(A));p;p;n2(r2(a;b;c;d;e;z(S(p;p(a(A));p;n2(r2(a;b;c;d;e;z(S(p;p(a(A));p;-)))))))))))))
        S(p;p;p;n2(r2(a;b;c;d;e;z(S(p(a(A));p;p;n2(r2(a;b;c;d;e;z(S(p;p(a(A));p;n2(r2(a;b;c;d;e;z(S(p;p(A);p;-)))))))))))))
        }
];

for my $input_length ( 1 .. 3 ) {
    my $recce = Marpa::Recognizer->new( { grammar => $grammar } );
    defined $recce->tokens( [ ( [ 'a', 'A' ] ) x $input_length ] )
        or Marpa::exception('Parsing exhausted');
    my $evaler = Marpa::Evaluator->new(
        {   recce => $recce,
            clone => 0,
        }
    );
    my $i = 0;
    while ( my $value = $evaler->value() and $i < 4 ) {
        my $result = ${$value};
        Marpa::Test::is( ${$value}, $results[$input_length][$i],
            "cycle with initial nullables, input length=$input_length, pass $i"
        );
        $i++;
    } ## end while ( my $value = $evaler->value() and $i++ < 4 )
} ## end for my $input_length ( 1 .. 3 )

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
