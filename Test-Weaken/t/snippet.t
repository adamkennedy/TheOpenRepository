#!perl

use strict;
use warnings;
use Test::More tests => 2;
use Fatal qw(open close);

use lib 't/lib';
use Test::Weaken::Test;

BEGIN { use_ok('Test::Weaken') }

## no critic (InputOutput::RequireBriefOpen)
open my $save_stdout, '>&STDOUT';
## use critic

use Test::Weaken qw(leaks);
use Data::Dumper;
use Math::BigInt;
use Math::BigFloat;
use Carp;
use English qw( -no_match_vars );

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

my $bad_destructor = sub {'I am useless'};

close STDOUT;
my $code_output;
open STDOUT, q{>}, \$code_output;

## use Marpa::Test::Display leaks snippet

my $test = Test::Weaken::leaks(
    {   constructor => $bad_test,
        destructor  => $bad_destructor,
    }
);
if ($test) {
    print "There are leaks\n" or croak("Cannot print to STDOUT: $ERRNO");
}

## no Marpa::Test::Display

open STDOUT, q{>&}, $save_stdout;
Test::Weaken::Test::is( $code_output, <<'EOS', 'leaks snippet' );
There are leaks
EOS

close STDOUT;
$code_output = undef;
open STDOUT, q{>}, \$code_output;

{
## use Marpa::Test::Display unfreed_proberefs snippet

    my $test = Test::Weaken::leaks($bad_test);
    if ($test) {
        my $unfreed_proberefs = $test->unfreed_proberefs();
        my $unfreed_count     = @{$unfreed_proberefs};
        printf "%d of %d references were not freed\n",
            $test->unfreed_count(), $test->probe_count()
            or croak("Cannot print to STDOUT: $ERRNO");
        print "These are the probe references to the unfreed objects:\n"
            or croak("Cannot print to STDOUT: $ERRNO");
        for my $proberef ( @{$unfreed_proberefs} ) {
            print Data::Dumper->Dump( [$proberef], ['unfreed'] )
                or croak("Cannot print to STDOUT: $ERRNO");
        }
    }

## no Marpa::Test::Display
}

open STDOUT, q{>&}, $save_stdout;
Test::Weaken::Test::is( $code_output, <<'EOS', 'unfreed_proberefs snippet' );
1 of 2 references were not freed
These are the probe references to the unfreed objects:
$unfreed = [
             42,
             711,
             $unfreed
           ];
EOS
