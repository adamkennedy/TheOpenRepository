use 5.010_000;
use strict;
use warnings;
use lib "../lib";

use Scalar::Util qw(refaddr reftype isweak weaken);
use Test::More;

BEGIN {
    eval "use Test::Weaken 0.002002";
    if ($@) {
        plan skip_all
            => "Test::Weaken 0.002002 required for testing of memory cycles";
        exit 0;
    } else {
        plan tests => 5;
    }
    use_ok( 'Parse::Marpa' );
}

my $test = sub {
    my $g = new Parse::Marpa::Grammar({
        start => "S",
        rules => [
            [ "S", [qw/A A A A/] ],
            [ "A", [qw/a/] ],
            [ "A", [qw/E/] ],
            [ "E" ],
        ],
        terminals => [
            [ "a" => { regex => qr/a/ } ],
        ],
    });
    my $a = $g->get_symbol("a");
    my $recce = new Parse::Marpa::Recognizer({grammar => $g});
    $recce->earleme([$a, "a", 1]);
    $recce->earleme([$a, "a", 1]);
    $recce->earleme([$a, "a", 1]);
    $recce->earleme([$a, "a", 1]);
    $recce->end_input();
    my $evaler = new Parse::Marpa::Evaluator($recce);
    die("No parse found") unless $evaler;
    $evaler->value();
    [ $g, $recce, $evaler ];
};

my ($weak_count, $strong_count, $unfreed_weak, $unfreed_strong)
    = Test::Weaken::poof($test);

cmp_ok($weak_count, "!=", 0, "Found $weak_count weak refs");
cmp_ok($strong_count, "!=", 0, "Found $strong_count strong refs");

cmp_ok(scalar @$unfreed_strong, "==", 0, "All strong refs freed")
    or diag("Unfreed strong refs: ", scalar @$unfreed_strong);

my %weak_ok;

my $unexpected_weak = [ grep { ! $weak_ok{$_ . ""}++ } @$unfreed_weak ];
    
cmp_ok(scalar @$unexpected_weak, "==", 0, "All weak refs freed")
    or diag("Unexpected unfreed weak refs: ", scalar @$unexpected_weak);

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
