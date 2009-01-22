#!perl

use strict;
use warnings;

use Test::More tests => 6;
use Test::Weaken;
use Scalar::Util qw(weaken);

BEGIN {
    use_ok('Test::Weaken');
}

sub brief_result {
    my $text = 'total: weak=' . (shift) . q{; };
    $text .= 'strong=' . (shift) . q{; };
    $text .= 'unfreed: weak=' . scalar @{ (shift) } . q{; };
    $text .= 'strong=' . scalar @{        (shift) };
    return $text;
} ## end sub brief_result

my $result = Test::Weaken::poof(
    sub {
        my $x = [];
        my $y = \$x;
        weaken( my $z = \$x );
        $z;
    }
);
cmp_ok( $result, q{==}, 0, 'Simple weak ref' );

is( brief_result(
        Test::Weaken::poof( sub { my $x = 42; my $y = \$x; $x = \$y; } )
    ),
    'total: weak=0; strong=3; unfreed: weak=0; strong=3',
    'Bad Less Simple Cycle'
);

is( brief_result(
        Test::Weaken::poof(
            sub { my $x; weaken( my $y = \$x ); $x = \$y; $y; }
        )
    ),
    'total: weak=1; strong=2; unfreed: weak=0; strong=0',
    'Fixed simple cycle'
);

is( brief_result(
        Test::Weaken::poof(
            sub {
                my $x;
                my $y = [ \$x ];
                my $z = { k1 => \$y };
                $x = \$z;
                [ $x, $y, $z ];
            }
        )
    ),
    'total: weak=0; strong=9; unfreed: weak=0; strong=5',
    'Bad Complicated Cycle'
);

is( brief_result(
        Test::Weaken::poof(
            sub {
                my $x = 42;
                my $y = [ \$x ];
                my $z = { k1 => \$y };
                weaken( $x = \$z );
                [ $x, $y, $z ];
            }
        )
    ),
    'total: weak=1; strong=8; unfreed: weak=0; strong=0',
    'Fixed Complicated Cycle'
);

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
