#!/usr/bin/perl

# Simple script to undock you when in the station

use strict;
use FindBin            ();
use File::Spec         ();
use EVE::Macro::Object ();

my $macro = EVE::Macro::Object->new;

$macro->left_click_target('station_undock');
$macro->sleep('undock');
$macro->left_click_target('ship_autopilot');

1;
