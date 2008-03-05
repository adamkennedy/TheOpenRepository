#!/usr/bin/perl

use strict;
use Test::More tests => 2;

ok ( $] >= 5.005, 'Your perl is new enough' );

use_ok( 'Win32::File::Object' );
