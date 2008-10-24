#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 10;
use File::Spec::Functions ':ALL';
use EVE::Macro::Object    ();
use Win32::Process::List  ();

# Data files
my $config = rel2abs(catfile( 'data', 'EVE-Macro.conf' ));
ok( -f $config, "Found test config at $config" );
my $object = EVE::Macro::Object->start(
	config_file => $config,
	username    => 'Algorithm2',
	password    => 'phlegm3{#}',
);
isa_ok( $object, 'EVE::Macro::Object' );
isa_ok( $object->process, 'Win32::Process' );
ok( $object->window, '->window ok' );

ok( $object->login, '->login  ok' );
foreach my $type ( qw{ Hydrogen Helium Oxygen Nitrogen } ) {
	ok(
		$object->market_search("$type Isotopes"),
		'->market_search ok',
	);
}
ok( $object->stop, '->stop ok' );

1;
