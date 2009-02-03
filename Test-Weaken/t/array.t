#!perl

use strict;
use warnings;

use Test::More tests => 2;
use Scalar::Util qw(weaken);
use Data::Dumper;

use lib 't/lib';
use Test::Weaken::Test;

BEGIN {
    use_ok('Test::Weaken');
}

my $test = new Test::Weaken(
    sub {
        my $x;
        my $y = [ \$x, 42 ];
        $x = [ \$y, 711 ];
        weaken( my $w1 = \$x );
        weaken( my $w2 = \$y );
        $x->[2] = \$w1;
        $y->[2] = \$w2;
        $x;
    }
);

my $unfreed_count     = $test->test();
my $probe_count       = $test->probe_count();
my $unfreed_proberefs = $test->unfreed_proberefs();

my $text = "Checking $probe_count objects\n"
    . "$unfreed_count objects were not freed:\n";

# names for the references, so checking the dump does not depend
# on the specific hex value of locations

for my $proberef ( @{$unfreed_proberefs} ) {
    $text .= Data::Dumper->Dump( [$proberef], [qw(unfreed)] );
}

Test::Weaken::Test::is( $text, <<'EOS', 'Dump of unfreed arrays' );
Checking 7 objects
6 objects were not freed:
$unfreed = [
             \[
                 \$unfreed,
                 42,
                 \$unfreed->[0]
               ],
             711,
             \${$unfreed->[0]}->[0]
           ];
$unfreed = \[
               \[
                   $unfreed,
                   711,
                   \${$unfreed}->[0]
                 ],
               42,
               \$unfreed
             ];
$unfreed = \\[
                 \[
                     ${$unfreed},
                     42,
                     \${${$unfreed}}->[0]
                   ],
                 711,
                 $unfreed
               ];
$unfreed = [
             \[
                 \$unfreed,
                 711,
                 \$unfreed->[0]
               ],
             42,
             \${$unfreed->[0]}->[0]
           ];
$unfreed = \[
               \[
                   $unfreed,
                   42,
                   \${$unfreed}->[0]
                 ],
               711,
               \$unfreed
             ];
$unfreed = \\[
                 \[
                     ${$unfreed},
                     711,
                     \${${$unfreed}}->[0]
                   ],
                 42,
                 $unfreed
               ];
EOS
