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
	nochanges     => \$NO_CHANGES,
	nocopyright   => \$NO_COPYRIGHT,
	nort          => \$NO_RT,
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
	no_changes   => $NO_CHANGES,
	no_copyright => $NO_COPYRIGHT,
	no_rt        => $NO_RT,
	no_test      => $NO_TEST,
);






######################################################################
# Execution

$release->run;
