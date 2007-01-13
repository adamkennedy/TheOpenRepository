#!/usr/bin/perl -w

# Load test the Perl::Metrics module

use strict;
use lib ();
use UNIVERSAL 'isa';
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	unless ( $ENV{HARNESS_ACTIVE} ) {
		require FindBin;
		$FindBin::Bin = $FindBin::Bin; # Avoid a warning
		chdir catdir( $FindBin::Bin, updir() );
		lib->import('blib', 'lib');
	}
}






# Does everything load?
use Test::More tests => 5;

ok( $] >= 5.005, 'Your perl is new enough' );

# Load Perl::Metrics. Can it be found in the plugin list?
require_ok( 'Perl::Metrics' );
my @plugins = Perl::Metrics->plugins;
ok( scalar(@plugins), 'Found at least one plugin' );
ok( scalar(grep { $_ eq 'Perl::Metrics::Plugin::MinimumVersion' } @plugins),
	'Found Perl::Metrics::Plugin::MinimumVersion' );

# Load the plugin itself
use_ok( 'Perl::Metrics::Plugin::MinimumVersion' );

1;
