#!/usr/bin/perl

BEGIN {
    $|  = 1;
    $^W = 1;
}

use Test::More tests => 2;
use File::Spec::Functions ':ALL';
use SQL::Script;

my $simple = catfile( 't', 'data', 'simple.sql' );
ok( -f $simple, "$simple exists" );





#####################################################################
# Create and work with simple scripts

my $script = SQL::Script->new;
isa_ok( $script, 'SQL::Script' );
is( $script->split_by, ";\n", '->split_by default ok' );
is_deeply( [ $script->statements ], [], '->statements returns empty list by default' );
