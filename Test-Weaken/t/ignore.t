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

our %cache;

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
use Test::Weaken;
use Scalar::Util;

my @weaken = Test::Weaken::leaks(
    {   constructor => sub { MyObject->new },
        ignore      => sub {
            my ($thing) = @_;
            return ( Scalar::Util::blessed($thing)
                    && $thing->isa('MyGlobal') );
            }
    }
);
use Data::Dumper;
print Dumper( \@weaken );

# print Dumper(\%MyGlobal::cache);
