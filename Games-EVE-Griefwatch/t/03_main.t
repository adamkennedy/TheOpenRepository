#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
use File::Spec::Functions ':ALL';
use LWP::Online 'online';
use Games::EVE::Griefwatch;

if ( online() ) {
	plan( tests => 9 );
} else {
	plan( skip_all => 'This test requires the Internet' );
}

# Test data
my $KILLBOARD_NAME = 'udie';
my $KILLMAIL_ID    = 15256;
my $KILLMAIL_RAW   = <<'END_KILLMAIL';
2007.04.12 20:35

Victim: Langly
Alliance: GoonSwarm
Corp: GoonFleet
Destroyed: Kestrel
System: Odebeinn
Security: 0.3

Involved parties:

Name: Shin Ra (laid the final blow)
Security: -1.2
Alliance: Terra Incognita.
Corp: BURN EDEN
Ship: Punisher
Weapon: Dual Modulated Light Energy Beam I

Destroyed items:

Medium F-S9 Regolith Shield Induction
Power Diagnostic System I
Micro Auxiliary Power Core I
Invulnerability Field I
'Malkuth' Standard Missile Launcher I
'Malkuth' Standard Missile Launcher I
Bloodclaw Light Missile, Qty: 1374 (Cargo)
Bloodclaw Light Missile, Qty: 19
Bloodclaw Light Missile, Qty: 20
END_KILLMAIL





#####################################################################
# Main Testing

# Create the object
my $killboard = Games::EVE::Griefwatch->new(
	name => $KILLBOARD_NAME,
	);
isa_ok( $killboard, 'Games::EVE::Griefwatch' );
is( $killboard->name, $KILLBOARD_NAME, '->name ok'   );
is( $killboard->trace, 0,      '->trace ok'  );
isa_ok( $killboard->mech, 'WWW::Mechanize'   );

# Get some standard pages
ok( $killboard->get_home,   '->get_home ok'   );
ok( $killboard->get_kills,  '->get_kills ok'  );
ok( $killboard->get_losses, '->get_losses ok' );

# Fetch a killmail page
ok( $killboard->get_details( $KILLMAIL_ID ), '->got_details ok' );

# Fetch a raw killmail
my $rawmail = $killboard->rawmail( $KILLMAIL_ID );
is( $rawmail, $KILLMAIL_RAW, '->rawmail works as expected' );
