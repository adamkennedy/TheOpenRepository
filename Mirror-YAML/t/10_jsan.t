#!/usr/bin/perl

# Compile testing for Mirror::YAML

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use LWP::Online ':skip_all';
use Test::More tests => 13;
use File::Spec::Functions ':ALL';
use Mirror::YAML;

my $test_dir  = catdir('t', 'data', 'svn1');
my $test_file = catfile($test_dir, 'mirror.yml');
ok( -d $test_dir,  'Found test directory' );
ok( -f $test_file, 'Found test file'      );





#####################################################################
# Local Half

# Load the mirror
my $test_conf = Mirror::YAML->read($test_dir);
isa_ok( $test_conf, 'Mirror::YAML' );
is( $test_conf->version, '1.0', '->version ok' );
is( $test_conf->name, 'SVN Test Repository', '->name ok' );
isa_ok( $test_conf->master, 'URI::http' );

# Check the timing numbers
my $number = qr/^\d+\.\d*$/;
is( $test_conf->timestamp, 1220649472, '->timestamp ok' );
like( $test_conf->lastget, $number,    '->lastget ok'   );
like( $test_conf->lag,     $number,    '->lag ok'       );
like( $test_conf->age,     $number,    '->age ok'       );





#####################################################################
# Online Half

my $master = $test_conf->get_master;
isa_ok( $master, 'Mirror::YAML' );
is( $master->valid, 1, '->valid ok' );
