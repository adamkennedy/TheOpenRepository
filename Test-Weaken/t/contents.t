#!/usr/bin/perl

# This code, as is the case with much of the other test code is
# modified in minor ways from the original test case created
# by Kevin Ryde.

# Kevin Ryde: MyObject has data hidden away from Test::Weaken's normal
# traversals, in this case separate %data and %moredata hashes.  This is
# like an "inside-out" object, and as is sometimes done for extra data
# in a subclass.  It also resembles case where data is kept only in C
# code structures.

package MyObject;
use strict;
use warnings;

my %data;
my %moredata;

sub new {
    my ($class) = @_;
    my $scalar = 'this is a myobject';
    my $self = bless \$scalar, $class;
    $data{ $self + 0 } = ['extra data'];
    $moredata{ $self + 0 } = [ 'more extra data', ['with a sub-array too'] ];
    return $self;
} ## end sub new

sub DESTROY {
    my ($self) = @_;
    delete $data{ $self + 0 };
    delete $moredata{ $self + 0 };
} ## end sub DESTROY

sub data {
    my ($self) = @_;
    return $data{ $self + 0 };
}

sub moredata {
    my ($self) = @_;
    return $data{ $self + 0 };
}

package main;
use strict;
use warnings;
use Test::Weaken;
use Test::More tests => 5;

sub myobject_contest_func {
    my ($obj) = @_;
    return $obj->data, $obj->moredata;
}

{
    my $test = Test::Weaken::leaks(
        {   constructor => sub { return MyObject->new },
            contents    => \&myobject_contest_func
        }
    );
    Test::More::is( $test, undef, 'good weaken of MyObject' );
}

{
    my $leak;
    my $test = Test::Weaken::leaks(
        {   constructor => sub {
                my $obj = return MyObject->new;
                $leak = $obj->data;
                return $obj;
            },
            contents => \&myobject_contest_func,
        }
    );
    Test::More::ok( $test, 'leaky "data" detection' );
    Test::More::is( $test && $test->unfreed_count, 1, 'one object leaked' );
}

{
    my $leak;
    my $test = Test::Weaken::leaks(
        {   constructor => sub {
                my $obj = return MyObject->new;
                $leak = $obj->moredata;
                return $obj;
            },
            contents => \&myobject_contest_func,
        }
    );
    Test::More::ok( $test, 'leaky "moredata" detection' );
    Test::More::is( $test && $test->unfreed_count, 2, 'one object leaked' );
}

exit 0;
