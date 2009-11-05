#!perl

# the example grammar in Aycock/Horspool "Practical Earley Parsing",
# _The Computer Journal_, Vol. 45, No. 6, pp. 620-630,
# in its "NNF" form

use 5.010;
use strict;
use warnings;

use lib 'lib';
use Test::More tests => 6;
use t::lib::Marpa::Test;

BEGIN {
    Test::More::use_ok('Marpa');
}

## no critic (Subroutines::RequireArgUnpacking)

sub rank_zero { return 0 }
sub rank_one { return -.01 }
sub zero { return '0' }
sub one { return '1' }

sub start_rule_action {
    shift;
    return join q{}, @_;
}

## use critic

my $grammar = Marpa::Grammar->new(
    {   start       => 'S',
        strip       => 0,
        parse_order => 'numeric',
        rules       => [
            {   lhs    => 'S',
                rhs    => [qw/digit digit digit digit/],
                action => 'main::start_rule_action'
            },
            {   lhs            => 'digit',
                rhs            => ['zero'],
                ranking_action => 'main::rank_zero',
                action         => 'main::zero'
            },
            {   lhs            => 'digit',
                rhs            => ['one'],
                ranking_action => 'main::rank_one',
                action         => 'main::one'
            },
            {   lhs => 'one',
                rhs => ['t'],
            },
            {   lhs => 'zero',
                rhs => ['t'],
            },
        ],
        terminals => [qw(t)],
    }
);

$grammar->precompute();

my $recce = Marpa::Recognizer->new( { grammar => $grammar, clone => 0 } );

my $input_length = 4;
$recce->tokens( [ ( [ 't' ] ) x $input_length ] );

my @expected = ( q{}, qw[(;;;a) (;;a;a) (;a;a;a) (a;a;a;a)] );

my $evaler = Marpa::Evaluator->new(
    {   recce => $recce,
        clone => 0,
    }
);

while ( my $result = $evaler->value() ) {
    state $i = 0;
    say ${$result};
    # Test::More::is( ${$result}, $expected[$i], "counter $i" );
    $i++;
}

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
