#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More             tests => 2;
use File::Spec::Functions  ':ALL';
use Games::EVE::Griefwatch ();

my $KILLS_FILE = catfile( 't', 'data', 'kills.html' );
ok( -f $KILLS_FILE, 'Test kills data exists' );





#####################################################################
# Page Testing

# Test a kills page
SCOPE: {
	open( KILLS, $KILLS_FILE ) or die "open: $!";
	local $/ = undef;
	my $html = <KILLS>;
	close( KILLS );

	my @ids = Games::EVE::Griefwatch->parse_ids( \$html );
	is_deeply( \@ids, [ qw{
		16486
		16485
		16478
		16479
		16477
		16476
		16475
		16474
		16473
		16472
		16464
		16469
		16468
		16467
		16466
		16465
		16455
		16453
		16451
		16452
		16450
		16447
		16449
		16448
		16444
		16443
		16442
		16441
		16440
		16439
		} ], 'Found expected ids',
	);

	my $next_uri = Games::EVE::Griefwatch->parse_next( \$html );
	is( $next_uri, '?p=kills&page=2', 'Got expected next URI' );
}
