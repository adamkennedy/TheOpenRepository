#!/usr/bin/perl

use 5.008;
use strict;
use warnings;
use ADAMK::Lacuna::Client;
use ADAMK::Lacuna::Bot;

unless ( -f 'lacuna.yml' ) {
  exit(0);
}

# Check input
my $name = shift(@ARGV) or die "Did not provide an agent name";

# Load the empire
print "Searching for spy '$name'...\n";
my $client = ADAMK::Lacuna::Client->new;
my $empire = $client->empire;
my $spy    = $empire->spy( name => $name );

# Generate a summary of the spy
print "Spy:         " . $spy->name               . "\n";
print "Level:       " . $spy->level              . "\n";
print "Deception:   " . $spy->deception          . "\n";
print "Espionage:   " . $spy->espionage          . "\n";
print "Security:    " . $spy->security           . "\n";
print "Offense:     " . $spy->offense            . "\n";
print "Defense:     " . $spy->defense            . "\n";
print "Level:       " . $spy->level              . "\n";
print "My Level:    " . $spy->mylevel            . "\n";
print "Intel:       " . $spy->intel              . "\n";
print "  Power:     " . $spy->intel_power        . "\n";
print "  Toughness: " . $spy->intel_toughness    . "\n";
print "Mayhem:      " . $spy->mayhem             . "\n";
print "  Power:     " . $spy->mayhem_power       . "\n";
print "  Toughness: " . $spy->mayhem_toughness   . "\n";
print "Theft:       " . $spy->theft              . "\n";
print "  Power:     " . $spy->theft_power        . "\n";
print "  Toughness: " . $spy->theft_toughness    . "\n";
print "Politics:    " . $spy->politics           . "\n";
print "  Power:     " . $spy->politics_power     . "\n";
print "  Toughness: " . $spy->politics_toughness . "\n";
print "---------------------------------------------\n";

# Where is the spy?
my $target = $spy->assigned_to;
print "Target: " . $target->name . "\n";

1;
