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
use Test::More tests => 8;
use Perl::Metrics::Plugin::MinimumVersion;
use constant MV => 'Perl::Metrics::Plugin::MinimumVersion';

# Check the metrics have versions
my $metrics = MV->metrics;
ok( $metrics->{explicit}, "Metric 'explicit' has a version" );
ok( $metrics->{syntax},   "Metric 'explicit' has a version" );





# Test a sample with a syntax version and no explicit version
{
my $Document = PPI::Document->new(\<<END_PERL);
package Foo;
use 5.006;
1;
END_PERL
isa_ok( $Document, 'PPI::Document' );
is( MV->metric_explicit($Document), 'v5.6.0', 'Got explicit version when expected'    );
is( MV->metric_syntax($Document),    '',      'Got null syntax version when expected' );
}





# Test a sample with a explicit and no syntax version
{
my $Document = PPI::Document->new(\<<END_PERL);
package Foo;
use utf8;
1;
END_PERL
isa_ok( $Document, 'PPI::Document' );
is( MV->metric_explicit($Document), '',       'Got null explicit version when expected' );
is( MV->metric_syntax($Document),   'v5.8.0', 'Got syntax version when expected'        );
}

1;
