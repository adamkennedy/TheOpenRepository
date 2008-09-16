# The tests from Lincoln Stein's Devel::Cycle module

use Test::More tests => 4;

use Scalar::Util qw(weaken isweak);

BEGIN { use_ok('Test::Weaken') };

sub brief_result {
   my $text = "total: weak=" . (shift) . "; ";
   $text .= "strong=" . (shift) . "; ";
   $text .= "unfreed: weak=" . scalar @{(shift)} . "; ";
   $text .= "strong=" . scalar @{(shift)};
}

sub stein_1 {
    my $test = {fred   => [qw(a b c d e)],
		ethel  => [qw(1 2 3 4 5)],
		george => {martha => 23,
			   agnes  => 19}
	       };
    $test->{george}{phyllis} = $test;
    $test->{fred}[3]      = $test->{george};
    $test->{george}{mary} = $test->{fred};
    $test;
}


sub stein_w1 {
    my $test = stein_1();
    weaken($test->{george}->{phyllis});
    $test;
}

sub stein_w2 {
    my $test = stein_1();
    weaken($test->{george}->{phyllis});
    weaken($test->{fred}[3]);
    $test;
}

is( brief_result( Test::Weaken::poof(\&stein_1) ),
    "total: weak=0; strong=7; unfreed: weak=0; strong=7",
    "Stein's test"
);

is( brief_result( Test::Weaken::poof(\&stein_w1) ),
    "total: weak=1; strong=6; unfreed: weak=0; strong=2",
    "Stein's test weakened once"
);

is( brief_result( Test::Weaken::poof(\&stein_w2) ),
    "total: weak=2; strong=5; unfreed: weak=0; strong=0",
    "Stein's test weakened twice"
);

