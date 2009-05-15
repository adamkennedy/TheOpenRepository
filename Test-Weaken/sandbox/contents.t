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

use Test::More tests => 3;
use English qw( -no_match_vars );
use Fatal qw(open close);
use Test::Weaken;
use Data::Dumper;

use lib 't/lib';
use Test::Weaken::Test;

my %data;
my %moredata;

sub new {
    my ($class) = @_;
    my $self = [];
    $data{ $self + 0 } = ['extra data'];
    $moredata{ $self + 0 } = [ 'more extra data', ['with a sub-array too'] ];
    return bless $self, $class;
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
    return $moredata{ $self + 0 };
}

package main;

## use Marpa::Test::Display contents snippet

sub myobject_contents_func {
    my ($probe) = @_;
    return unless Scalar::Util::blessed(${$probe});
    print STDERR Data::Dumper::Dumper($probe);
    my $obj = ${$probe};
    return unless $obj->isa('MyObject');
    return (${$probe}->data, ${$probe}->moredata);
} ## end sub myobject_contents_func

{
    my $test = Test::Weaken::leaks(
        {   constructor => sub { return MyObject->new },
            contents    => \&myobject_contents_func
        }
    );
    Test::More::is( $test, undef, 'good weaken of MyObject' );
}

## no Marpa::Test::Display

# Leaky Data Detection
{
    my $leak;
    my $tester = Test::Weaken::leaks(
        {   constructor => sub {
                my $obj = return MyObject->new;
                $leak = $obj->data;
                return $obj;
            },
            contents => \&myobject_contents_func,
        }
    );
    my $test_name = 'leaky data detection';
    if (not $tester) {
        Test::More::fail( $test_name );
    } else {
        Test::More::is_deeply(
            $leak, MyObject->new->data,
            $test_name );
    }
}

# More Leaky Data Detection
{
    my $leak;
    my $test = Test::Weaken::leaks(
        {   constructor => sub {
                my $obj = return MyObject->new;
                $leak = $obj->moredata;
                return $obj;
            },
            contents => \&myobject_contents_func,
        }
    );
    my $test_name = q{leaky moredata detection};
    if (not $test) {
        Test::More::fail( $test_name );
    } else {
        Test::More::is_deeply(
            $leak, MyObject->new->moredata,
            $test_name );
    }
}

exit 0;
