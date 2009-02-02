#!perl

use strict;
use warnings;

use Test::More tests => 3;
use Data::Dumper;

use lib 't/lib';
use Test::Weaken::Test;

BEGIN {
    use_ok('Test::Weaken');
}

my $result;

{
    my $leak;
    my @weaken = Test::Weaken::poof(
        sub {
            my $aref = ['abc'];
            my $obj = { array => $aref };
            $leak = $aref;
            return $obj;
        }
    );
    $result =
          Data::Dumper->Dump( [ \@weaken ], ['weaken'] )
        . Data::Dumper->Dump( [$leak], ['leak'] );
}
Test::Weaken::Test::is( $result, <<'EOS', 'CPAN Bug ID 42903, example 1' );
$weaken = [
            0,
            3,
            [],
            [
              [
                'abc'
              ]
            ]
          ];
$leak = [
          'abc'
        ];
EOS

{
    my $leak;
    my @weaken = Test::Weaken::poof(
        sub {
            my $aref = [ 'def', ['ghi'] ];
            my $obj = { array => $aref };
            $leak = $aref;
            return $obj;
        }
    );
    $result =
          Data::Dumper->Dump( [ \@weaken ], ['weaken'] )
        . Data::Dumper->Dump( [$leak], ['leak'] );
}
Test::Weaken::Test::is( $result, <<'EOS', 'CPAN Bug ID 42903, example 2' );
$weaken = [
            0,
            4,
            [],
            [
              [
                'def',
                [
                  'ghi'
                ]
              ],
              $weaken->[3][0][1]
            ]
          ];
$leak = [
          'def',
          [
            'ghi'
          ]
        ];
EOS
