#!perl

use strict;
use warnings;

# The tests from Lincoln Stein's Devel::Cycle module

use Scalar::Util qw(weaken isweak);
use Test::More tests => 4;

use lib 't/lib';
use Test::Weaken::Test;

BEGIN { use_ok('Test::Weaken') }

sub brief_result {
    my $test              = shift;
    my $unfreed_count     = $test->test();
    my $unfreed_proberefs = $test->unfreed_proberefs();

    my @unfreed_strong = ();
    my @unfreed_weak   = ();
    for my $proberef ( @{$unfreed_proberefs} ) {
        if ( ref $proberef eq 'REF' and isweak ${$proberef} ) {
            push @unfreed_weak, $proberef;
        }
        else {
            push @unfreed_strong, $proberef;
        }
    }

    return
          'total: weak='
        . $test->weak_probe_count() . q{; }
        . 'strong='
        . $test->strong_probe_count() . q{; }
        . 'unfreed: weak='
        . ( scalar @unfreed_weak ) . q{; }
        . 'strong='
        . ( scalar @unfreed_strong );
}

sub stein_1 {
    my $test = {
        fred   => [qw(a b c d e)],
        ethel  => [qw(1 2 3 4 5)],
        george => {
            martha => 23,
            agnes  => 19
        }
    };
    $test->{george}{phyllis} = $test;
    $test->{fred}[3]         = $test->{george};
    $test->{george}{mary}    = $test->{fred};
    return $test;
}

sub stein_w1 {
    my $test = stein_1();
    weaken( $test->{george}->{phyllis} );
    return $test;
}

sub stein_w2 {
    my $test = stein_1();
    weaken( $test->{george}->{phyllis} );
    weaken( $test->{fred}[3] );
    return $test;
}

Test::Weaken::Test::is(
    brief_result( new Test::Weaken( \&stein_1 ) ),
    'total: weak=0; strong=5; unfreed: weak=0; strong=4',
    q{Stein's test}
);

Test::Weaken::Test::is(
    brief_result( new Test::Weaken( \&stein_w1 ) ),
    'total: weak=0; strong=5; unfreed: weak=0; strong=2',
    q{Stein's test weakened once}
);

Test::Weaken::Test::is(
    brief_result( new Test::Weaken( \&stein_w2 ) ),
    'total: weak=0; strong=5; unfreed: weak=0; strong=0',
    q{Stein's test weakened twice}
);

