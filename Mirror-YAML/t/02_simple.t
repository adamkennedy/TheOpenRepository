#!/usr/bin/perl

# Compile testing for Mirror::YAML

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 10;
use File::Spec::Functions ':ALL';
use Mirror::YAML;

my $simple_dir  = catdir('t', 'data', 'simple');
my $simple_file = catfile($simple_dir, 'mirror.yml');
ok( -d $simple_dir,  'Found test directory' );
ok( -f $simple_file, 'Found test file'      );

# Load the mirror
my $simple_conf = Mirror::YAML->read($simple_dir);
isa_ok( $simple_conf, 'Mirror::YAML' );
is( $simple_conf->name, 'JavaScript Archive Network', '->name ok' );
isa_ok( $simple_conf->master, 'URI::http' );
is( scalar($simple_conf->mirrors), 14, 'Got 14 mirrors' );

# Check the timing numbers
my $number = qr/^\d+\.\d*$/;
is( $simple_conf->timestamp, 1168895872, '->timestamp ok' );
like( $simple_conf->lastget, $number,    '->lastget ok'   );
like( $simple_conf->lag,     $number,    '->lag ok'       );
like( $simple_conf->age,     $number,    '->age ok'       );
