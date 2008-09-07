#!/usr/bin/perl

# Compile testing for Mirror::YAML

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 13;
use File::Spec::Functions ':ALL';
use Mirror::YAML;
use LWP::Online 'online';

my $simple_dir  = catdir('t', 'data');
my $simple_file = catfile('t', 'data', 'mirror.yml');
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






# Fetch URIs
SKIP: {
	skip("Not online", 3) unless online;
	my $rv = $simple_conf->check_mirrors;
	ok( $rv, '->get_all ok' );

	# Get some mirrors
	my @m = $simple_conf->select_mirrors;
	ok( scalar(@m), 'Got at least 1 mirror' );
	isa_ok( $m[0], 'URI', 'Got at least 1 URI object' );
}
