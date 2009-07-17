#!/usr/bin/perl

use strict;
use warnings;
use Test::Weaken;
use Test::More tests => 4;

## no critic (Miscellanea::ProhibitTies)

package MyTie;

my $leaky;

sub TIESCALAR {
    my ($class) = @_;
    my $tobj = bless {}, $class;
    $leaky = $tobj;
    return $tobj;
} ## end sub TIESCALAR

sub TIEHASH {
    goto \&TIESCALAR;
}

sub FIRSTKEY {
    return;    # no keys
}

sub TIEARRAY {
    goto \&TIESCALAR;
}

sub FETCHSIZE {
    return 0;    # no array elements
}

sub TIEHANDLE {
    goto \&TIESCALAR;
}

package main;

{
    my $test = Test::Weaken::leaks(
        sub {
            my $var;
            tie $var, 'MyTie';
            return \$var;
        }
    );
    my $unfreed_count = $test ? $test->unfreed_count() : 0;
    Test::More::is( $unfreed_count, 1, 'caught unfreed tied scalar' );
}

{
    my $test = Test::Weaken::leaks(
        sub {
            my %var;
            tie %var, 'MyTie';
            return \%var;
        }
    );
    my $unfreed_count = $test ? $test->unfreed_count() : 0;
    Test::More::is( $unfreed_count, 1, 'caught unfreed tied hash' );
}

{
    my $test = Test::Weaken::leaks(
        sub {
            my @var;
            tie @var, 'MyTie';
            return \@var;
        }
    );
    my $unfreed_count = $test ? $test->unfreed_count() : 0;
    Test::More::is( $unfreed_count, 1, 'caught unfreed tied array' );
}

{
    my $test = Test::Weaken::leaks(
        {   constructor => sub {
                tie *MYFILEHANDLE, 'MyTie';
                return \*MYFILEHANDLE;
            },
            tracked_types => ['GLOB'],
        }
    );
    my $unfreed_count = $test ? $test->unfreed_count() : 0;
    Test::More::is( $unfreed_count, 1, 'caught unfreed tied file handle' );
}

exit 0;
