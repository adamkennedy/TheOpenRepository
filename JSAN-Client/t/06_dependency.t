#!/usr/bin/perl -w

# Basic test for JSAN::Index

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 8;

use JSAN::Transport;
use JSAN::Index;





#####################################################################
# Main tests

# Can we load the release source?
foreach my $params ( [], [ build => 1 ] ) {
	my $Source = JSAN::Index::Release::_Source->new( @$params );
	isa_ok( $Source, 'JSAN::Index::Release::_Source' );
	ok( $Source->load, 'JSAN::Index::Release::_Source loads ok' );
}

# Get an installation Alg:Dep object
my $Install = JSAN::Index->dependency;
isa_ok( $Install, 'Algorithm::Dependency' );
isa_ok( $Install, 'JSAN::Index::Release::_Dependency' );

# Test getting a schedule
my $schedule = $Install->schedule( 'Display.Swap' );
ok( scalar(@$schedule), 'Got at least one item in the schedule' );
my @dists = grep { m{^/dist/} } @$schedule;
is( scalar(@dists), scalar(@$schedule), 'All returned values are dist paths' );

exit(0);
