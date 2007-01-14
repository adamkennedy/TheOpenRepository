#!/usr/bin/perl -w

# Compile testing for Mirror::Config

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 4;
use File::Spec::Functions ':ALL';
use Mirror::Config;

my $simple_file = catfile('t', 'data', 'simple.yaml');
ok( -f $simple_file, "Found test file" );
my $simple_conf = Mirror::Config->read($simple_file);
isa_ok( $simple_conf, 'Mirror::Config' );
is( $simple_conf->name, 'JavaScript Archive Network', '->name ok' );
isa_ok( $simple_conf->source, 'URI' );

exit(0);
