#!/usr/bin/perl

# Test that our META.yml dependencies are actually fulfilled

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

my $MODULE = 'Parse::CPAN::Meta 0.05';

# Don't run tests for installs
use Test::More;
unless ( $ENV{AUTOMATED_TESTING} or $ENV{RELEASE_TESTING} ) {
	plan( skip_all => "Author tests not required for installation" );
}

# Load the testing module
eval "use $MODULE";
if ( $@ ) {
	$ENV{RELEASE_TESTING}
	? die( "Failed to load required release-testing module $MODULE" )
	: plan( skip_all => "$MODULE not available for testing" );
}

plan( 'no_plan' );





#####################################################################
# Checks are hand-written for now

my $file = 'META.yml';
ok( -f $file, 'Found META.yml' );
my $meta = Parse::CPAN::Meta::LoadFile($file);
is( ref($meta), 'HASH', 'META.yml content is a HASH' );

hash( $meta->{requires}           );
hash( $meta->{build_requires}     );
hash( $meta->{test_requires}      );
hash( $meta->{configure_requires} );

sub hash {
	my $hash = shift or return;
	foreach my $module ( sort keys %$hash ) {
		module( $module => $hash->{$module} );
	}
}

sub module {
	my $module = shift;
	my $need   = normalise(shift);

	# Map the the %INC file name
	my $file = file($module);
	return if $INC{$file};

	# Locate the actual file
	my $path = path($file);
	return unless defined $path;

	# Load the version
	my $got = normalise(version($path));
	Test::More::ok( $got >= $need, "$module version ok ($got >= $need)" );
}

sub file {
	my $module = shift;
	$module =~ s/::/\//g;
	$module .= '.pm';
	return $module;
}

sub path {
	my @found = grep { -f $_ } map { "$_/$_[0]" } @INC;
	return $found[0];
}

sub version {
	require ExtUtils::MM_Unix;
	ExtUtils::MM_Unix->parse_version($_[0]);
}

sub normalise {
	my $v = shift;
	$v = 0 unless defined $v;
	$v =~ s/^([1-9])\.([1-9]\d?\d?)$/sprintf("%d.%03d",$1,$2)/e;
	$v =~ s/^([1-9])\.([1-9]\d?\d?)\.(0|[1-9]\d?\d?)$/sprintf("%d.%03d%03d",$1,$2,$3 || 0)/e;
	$v =~ s/(\.\d\d\d)000$/$1/;
	$v =~ s/_.+$//;
	if ( ref($v) ) {
		$v = $v + 0; # Numify
	}
	return $v;
}
