#!/usr/bin/perl

use 5.10.0;
use strict;
use warnings;
use ADAMK::Release ();

our $VERSION = '0.01';





######################################################################
# Configuration

my $VERBOSE      = '';
my $NO_CHANGES   = '';
my $NO_COPYRIGHT = '';
my $NO_RT        = '';
my $NO_TEST      = '';

# Set the settings and arg the arguments
Getopt::Long::GetOptions(
	verbose       => \$VERBOSE,
	nort          => \$NO_RT,
	nochanges     => \$NO_CHANGES,
	notest        => \$NO_TEST,
);

# Get the module name
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
