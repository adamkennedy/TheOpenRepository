#!perl

use 5.010_000;
use strict;
use warnings;
use lib 'lib';
use lib 't/lib';

use Carp;
use Scalar::Util qw(refaddr reftype isweak weaken);
use Test::More tests => 5;
use Test::Weaken;

BEGIN { use_ok( 'Parse::Marpa' ); }

my $test = sub {
    my $g = new Parse::Marpa::Grammar({
        start => 'S',
        rules => [
            [ 'S', [qw/A A A A/] ],
            [ 'A', [qw/a/] ],
            [ 'A', [qw/E/] ],
            [ 'E' ],
        ],
        terminals => [
            [ 'a' => { regex => qr/a/m } ],
        ],
    });
    my $a = $g->get_symbol('a');
    my $recce = new Parse::Marpa::Recognizer({grammar => $g});
    $recce->earleme([$a, 'a', 1]);
    $recce->earleme([$a, 'a', 1]);
    $recce->earleme([$a, 'a', 1]);
    $recce->earleme([$a, 'a', 1]);
    $recce->end_input();
    my $evaler = new Parse::Marpa::Evaluator( { recce => $recce } );
    croak('No parse found') unless $evaler;
    $evaler->value();
    [ $g, $recce, $evaler ];
};

my $result = Test::Weaken::poof($test);
say 'scalar result: ', $result;

my @result = Test::Weaken::poof($test);
my $weak_freed = $result[0] - @{$result[2]};
my $strong_freed = $result[1] - @{$result[3]};
my ($weak_count, $strong_count, $unfreed_weak, $unfreed_strong) = @result;
say "Weak, freed: $weak_freed  unfreed: ", @{$unfreed_weak}+0, "  total: $weak_count";
say "Strong, freed: $strong_freed  unfreed: ", @{$unfreed_strong}+0, "  total: $strong_count";

cmp_ok($weak_count, q{!=}, 0, "Found $weak_count weak refs");
cmp_ok($strong_count, q{!=}, 0, "Found $strong_count strong refs");

cmp_ok(scalar @{$unfreed_strong}, q{==}, 0, 'All strong refs freed')
    or diag('Unfreed strong refs: ', scalar @{$unfreed_strong});

my %weak_ok;

my $unexpected_weak = [ grep { ! $weak_ok{ $_ . q{} }++ } @{$unfreed_weak} ];

cmp_ok(scalar @{$unexpected_weak}, q{==}, 0, 'All weak refs freed')
    or diag('Unexpected unfreed weak refs: ', scalar @{$unexpected_weak} );

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
