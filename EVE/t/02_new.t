#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 6;
use File::Spec::Functions ':ALL';
use EVE::Macro::Object ();

# Data files
my $config = rel2abs(catfile( 'data', 'EVE-Macro.conf' ));
ok( -f $config, "Found test config at $config" );
my $object = EVE::Macro::Object->new(
	# config_file => $config,
	# username    => 'Foo',
	# password    => 'password',
);
isa_ok( $object, 'EVE::Macro::Object' );
ok( $object->username, '->username ok' );
ok( $object->password, '->password ok' );
ok( -d $object->marketlogs, '->marketlogs ok' );
is( ref($object->patterns), 'HASH', '->patterns ok' );
