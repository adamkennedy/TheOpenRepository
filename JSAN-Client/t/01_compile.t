#!/usr/bin/perl

use strict;
BEGIN {
    $|  = 1;
    $^W = 1;
}

use Test::More tests => 4;

ok( $] >= 5.006, 'Perl version is new enough' );

require_ok( 'JSAN::Transport' );
use_ok( 'JSAN::Client' );
use_ok( 'JSAN::Index' );
