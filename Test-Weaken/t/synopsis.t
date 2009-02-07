#!perl

use strict;
use warnings;
use English qw( -no_match_vars );
use Test::More tests => 2;
use Fatal qw(open close);
use Carp;
use Scalar::Util qw(weaken isweak);

use lib 't/lib';
use Test::Weaken::Test;

BEGIN { use_ok('Test::Weaken') }

my $code_output;
open my $save_stdout, '>&STDOUT';
close STDOUT;
open STDOUT, q{>}, \$code_output;

## use Marpa::Test::Display synopsis

use Test::Weaken qw(leaks);
use Data::Dumper;
use Math::BigInt;
use Math::BigFloat;

my $good_test = sub {
   my $obj1 = new Math::BigInt('42');
   my $obj2 = new Math::BigFloat('7.11');
   [ $obj1, $obj2 ];
};  

my $bad_test = sub {
   my $array = [ 42, 711 ];
   push @{$array}, $array;
   $array;
};

my $bad_destructor = sub { "I don't work" };

if ( !leaks( $good_test ) ) {
    print "No leaks in test 1\n";
} else {
    print "There were memory leaks from test 1!\n";
}

my $test = Test::Weaken::leaks({
    constructor => $bad_test,
    destructor  => $bad_destructor,
});
if ( $test ) {
    my $unfreed_proberefs = $test->unfreed_proberefs();
    my $unfreed_count = @{$unfreed_proberefs};
    printf "Test 2: %d of %d original references were not freed\n",
        $test->unfreed_count(),
        $test->probe_count();
    print "These are the probe references to the unfreed objects:\n";
    for my $proberef ( @{$unfreed_proberefs} ) {
        print Data::Dumper->Dump( [$proberef], ['unfreed'] );
    }
}

## no Marpa::Test::Display 

open STDOUT, q{>&}, $save_stdout;

Test::Weaken::Test::is( $code_output, <<'EOS', 'synopsis output' );
No leaks in test 1
Test 2: 1 of 2 original references were not freed
These are the probe references to the unfreed objects:
$unfreed = [
             42,
             711,
             $unfreed
           ];
EOS
