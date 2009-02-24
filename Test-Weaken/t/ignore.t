#!perl

# The first, basic test case for the ignore option
# was supplied by Kevin Ryde.

use strict;
use warnings;

use Test::More tests => 3;
use Data::Dumper;

use lib 't/lib';
use Test::Weaken::Test;

package MyGlobal;

my %cache;

sub new {
    my ( $class, $name ) = @_;
    return (
        $cache{$name} ||= bless {
            name  => $name,
            array => ["something for $name"],
        },
        $class
    );
}

package MyObject;

sub new {
    my ($class) = @_;
    return bless {
        one => MyGlobal->new('foo'),
        two => MyGlobal->new('bar'),
    }, $class;
}

package main;

use Scalar::Util;
use Data::Dumper;

BEGIN {
    use_ok('Test::Weaken');
}

use lib 't/lib';
use Test::Weaken::Test;

my $test = Test::Weaken::leaks(
    {   constructor => sub { MyObject->new },
        ignore      => sub {
            my ($thing) = @_;
            return ( Scalar::Util::blessed($thing)
                    && $thing->isa('MyGlobal') );
            }
    }
);
if ( not $test ) {
    pass('good ignore');
}
else {
    Test::Weaken::Test::is( $test->unfreed_proberefs, q{}, 'good ignore' );
}

$test = Test::Weaken::leaks(
    {   constructor => sub { MyObject->new },
        ignore      => sub { return; }
    }
);
Test::Weaken::Test::is( Dumper( $test->unfreed_proberefs ),
    <<'EOS', 'no-op ignore' );
$VAR1 = [
          bless( {
                   'array' => [
                                'something for foo'
                              ],
                   'name' => 'foo'
                 }, 'MyGlobal' ),
          bless( {
                   'array' => [
                                'something for bar'
                              ],
                   'name' => 'bar'
                 }, 'MyGlobal' ),
          $VAR1->[0]{'array'},
          $VAR1->[1]{'array'}
        ];
EOS

