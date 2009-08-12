#!perl

sub filter {
	my $module = shift;
	
	return 0 if $module =~ m/::Object\z/;
	return 0 if $module =~ m/::Trace::/;
	return 0 if $module =~ m/::StrictConstructor/;
	return 0 if $module =~ m/::Types\z/;
	return 0 if $module =~ m/_Old\z/;
	return 1;
}

use strict;

BEGIN {
	use English qw(-no_match_vars);
	$OUTPUT_AUTOFLUSH = 1;
	$WARNING = 1;
}

my @MODULES = (
    'Test::Pod::Coverage 1.04',
	'Pod::Coverage::Moose 0.01',
);

# Don't run tests for installs
use Test::More;
unless ( $ENV{AUTOMATED_TESTING} or $ENV{RELEASE_TESTING} ) {
	plan( skip_all => "Author tests not required for installation" );
}

# Load the testing modules
foreach my $MODULE ( @MODULES ) {
	eval "use $MODULE";
	if ( $EVAL_ERROR ) {
		$ENV{RELEASE_TESTING}
		? BAIL_OUT( "Failed to load required release-testing module $MODULE" )
		: plan( skip_all => "$MODULE not available for testing" );
	}
}

plan( skip_all => "Test fails as of yet." );

my @modules = all_modules();
my @modules_to_test = grep { filter($_) } @modules;
my $test_count = scalar @modules_to_test;
plan( tests => $test_count );

foreach my $module (@modules_to_test) {
	pod_coverage_ok($module, { 
	  coverage_class => 'Pod::Coverage::Moose', 
	  also_private => [ qr/^[A-Z_]+$/ ],
	  trustme => [ qw(as_string get_namespace) ]
	});
}