#!/usr/bin/perl

# Compile testing for Mirror::YAML

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 4;
use File::Spec::Functions ':ALL';
use Mirror::YAML;
use LWP::Online 'online';

# Basic construction
my $simple_file = catfile('t', 'data', 'simple.yaml');
ok( -f $simple_file, "Found test file" );
my $simple_conf = Mirror::YAML->read($simple_file);
isa_ok( $simple_conf, 'Mirror::YAML' );
is( $simple_conf->name, 'JavaScript Archive Network', '->name ok' );
isa_ok( $simple_conf->uri, 'URI' );
is( $simple_conf->timestamp, 1168463872, '->timestamp ok' );





# Fetch URIs
SKIP: {
	skip("Not online", 1) unless online;
	my $rv = $simple_conf->get_all;
	ok( $rv, '->get_all ok' );
}

exit(0);
