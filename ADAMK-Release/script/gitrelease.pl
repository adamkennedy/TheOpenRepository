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

my $repository = lc shift @ARGV;
$repository =~ s/::/-/g;





######################################################################
# Initialisation

my $release = ADAMK::Release->new(
	github => {
		username   => 'adamkennedy',
		repository => $repository,
	},
);






######################################################################
# Execution

$release->run;
