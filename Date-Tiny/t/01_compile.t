#!/usr/bin/perl

# Tests that Date::Tiny compiles

use strict;
use Test::More tests => 2;

ok( $] >= 5.004, "Your perl is new enough" );
use_ok( 'Date::Tiny' );
