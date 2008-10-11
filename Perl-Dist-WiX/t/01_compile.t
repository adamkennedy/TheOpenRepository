#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 8;

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
	$Perl::Dist::WiX::File::VERSION,
	'Perl::Dist::WiX::File loaded ok',
);

ok(
	$Perl::Dist::WiX::Component::VERSION,
	'Perl::Dist::WiX::Component loaded ok',
);

ok(
	$Perl::Dist::WiX::Environment::VERSION,
	'Perl::Dist::WiX::Environment loaded ok',
);

ok(
	$Perl::Dist::WiX::Script::VERSION,
	'Perl::Dist::WiX::Script loaded ok',
);
