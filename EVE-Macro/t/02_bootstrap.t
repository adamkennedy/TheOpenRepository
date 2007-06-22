#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 2;
use File::Spec::Functions ':ALL';
use EVE::Macro::Object ();
use Win32::Process::List ();

# Data files
my $config = rel2abs(catfile( 'data', 'EVE-Macro.conf' ));
ok( -f $config, "Found test config at $config" );
my $object = EVE::Macro::Object->start( config_file => $config );

# Give EVE time to boot
sleep 20;

# Is it still running?
# ...

# Print the list of all processes
my $P = Win32::Process::List->new;
my %list = $P->GetProcesses();
foreach my $key ( sort { $a <=> $b } keys %list ) {
	diag( "$key: $list{$key}\n" );
}

my ($name, $PID) = $P->GetProcessPid('ExeFile');

1;
