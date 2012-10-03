#!/usr/bin/perl

use 5.10.0;
use strict;
use warnings;
use ADAMK::Release ();

our $VERSION = '0.01';





######################################################################
# Configuration

unless ( @ARGV ) {
	die "Missing or invalid distribution name";
}

my $module     = shift @ARGV;
my $repository = lc $module;
$repository =~ s/::/-/g;





######################################################################
# Initialisation

my $release = ADAMK::Release->new(
	module => $module,
	github => {
		username   => 'adamkennedy',
		repository => $repository,
	},
);






######################################################################
# Execution

$release->run;
