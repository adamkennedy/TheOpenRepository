#!/usr/bin/perl

use strict;
use FindBin            ();
use File::Spec         ();
use EVE::Macro::Object ();





#####################################################################
# Main Script

my $eve = EVE::Macro::Object->start;

while ( 1 ) {
	my $coord = $eve->mouse_xy;
	print "Mouse at: $coord->[0],$coord->[1]\n";
	sleep(1);
}

$eve->stop;
