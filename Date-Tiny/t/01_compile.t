#!/usr/bin/perl -w

# Tests that Date::Tiny compiles

use strict;
use Test::More tests => 2;

ok( $] >= 5.005, "Your perl is new enough" );
use_ok( 'Date::Tiny' );

exit(0);
