#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 11;
use Games::EVE::Killmail ();






#####################################################################
# Create a typical object

my $rawmail = <<'END_KILLMAIL';
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

my $killmail = Games::EVE::Killmail->parse_string( $rawmail );
isa_ok( $killmail, 'Games::EVE::Killmail' );
is( $killmail->victim,   'Langly',    '->victim ok'   );
is( $killmail->alliance, 'GoonSwarm', '->alliance ok' );
is( $killmail->corp,     'GoonFleet', '->corp ok'     );
is( $killmail->ship,     'Kestrel',   '->ship ok'     );
is( $killmail->system,   'Odebeinn',  '->system ok'   );
is( $killmail->security, '0.3',       '->security ok' );
is( scalar($killmail->involved), 1, '1 involved party' );
isa_ok( ($killmail->involved)[0], 'Games::EVE::Killmail::InvolvedParty' );
my @destroyed = $killmail->destroyed;
is( scalar(@destroyed), 9, '10 items destroyed' );
isa_ok( $destroyed[0], 'Games::EVE::Killmail::DestroyedItem' );
