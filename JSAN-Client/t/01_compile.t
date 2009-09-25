#!/usr/bin/perl

use strict;
BEGIN {
    $|  = 1;
    $^W = 1;
}

use Test::More tests => 3;
use File::Remove 'remove';

BEGIN { remove( \1, 'temp' ) if -e 'temp'; }
END   { remove( \1, 'temp' ) if -e 'temp'; }

use_ok( 'JSAN::Transport', mirror_local => 'temp' );
use_ok( 'JSAN::Client', { prune => 1 } );
