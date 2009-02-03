#!perl

# This is the test case for Bug 42903.  This bug was found by Kevin Ryde,
# and he supplied the basics of this test case.

use strict;
use warnings;

use Test::More tests => 3;
use Data::Dumper;

use lib 't/lib';
use Test::Weaken::Test;

BEGIN {
    use_ok('Test::Weaken');
}

my $result = q{};
{
    my $leak;
    my $test = Test::Weaken::leaks(
        sub {
            my $aref = ['abc'];
            my $obj = { array => $aref };
            $leak = $aref;
            return $obj;
        }
    );
    my $unfreed_proberefs = $test ? $test->unfreed_proberefs() : [];
    for my $proberef ( @{$unfreed_proberefs} ) {
        $result .= Data::Dumper->Dump( [$proberef], ['unfreed'] );
    }
    $result .= Data::Dumper->Dump( [$leak], ['leak'] );
}
Test::Weaken::Test::is( $result, <<'EOS', 'CPAN Bug ID 42903, example 1' );
$unfreed = [
             'abc'
           ];
$leak = [
          'abc'
        ];
EOS

$result = q{};
{
    my $leak;
    my $test = Test::Weaken::leaks(
        sub {
            my $aref = [ 'def', ['ghi'] ];
            my $obj = { array => $aref };
            $leak = $aref;
            return $obj;
        }
    );
    my $unfreed_proberefs = $test ? $test->unfreed_proberefs() : [];
    for my $proberef ( @{$unfreed_proberefs} ) {
        $result .= Data::Dumper->Dump( [$proberef], ['unfreed'] );
    }
    $result .= Data::Dumper->Dump( [$leak], ['leak'] );
}
Test::Weaken::Test::is( $result, <<'EOS', 'CPAN Bug ID 42903, example 2' );
$unfreed = [
             'def',
             [
               'ghi'
             ]
           ];
$unfreed = [
             'ghi'
           ];
$leak = [
          'def',
          [
            'ghi'
          ]
        ];
EOS
