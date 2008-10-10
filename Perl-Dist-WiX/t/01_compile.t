#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 5;

ok( $] >= 5.008, 'Perl version is new enough' );

use_ok( 'Perl::Dist::WiX' );

ok(
	$Perl::Dist::WiX::VERSION,
	'Perl::Dist::WiX loaded ok',
);

ok(
	$Perl::Dist::WiX::Types::VERSION,
	'Perl::Dist::Types::WiX loaded ok',
);

ok(
	$Perl::Dist::WiX::Script2::VERSION,
	'Perl::Dist::Script2::WiX loaded ok',
);
