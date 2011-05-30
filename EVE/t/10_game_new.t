#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 6;
use File::Spec::Functions ':ALL';
use EVE ();

# Data files
my $config = rel2abs(catfile( 'data', 'EVE.conf' ));
ok( -f $config, "Found test config at $config" );
my $object = EVE::Game->new(
	# config_file => $config,
	# username    => 'Foo',
	# password    => 'password',
);
isa_ok( $object, 'EVE::Game' );
ok( $object->username, '->username ok' );
ok( $object->password, '->password ok' );
isa_ok( $object->marketlogs, 'EVE::MarketLogs' );
is( ref($object->patterns), 'HASH', '->patterns ok' );
