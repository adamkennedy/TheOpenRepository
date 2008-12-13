#!/usr/bin/perl

BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 1;
use File::Spec::Functions ':ALL';
use ORLite::Migrate ();
use t::lib::Test;

# Check for migration patches
my $timeline = catdir( 't', 'data', 'trivial' );
ok( -d $timeline, 'Found timeline' );

# Locate patches
my $patches = ORLite::Migrate::patches( $timeline );
is_deeply( $patches, [
	undef,
	migrate

# Set up the file
my $file = test_db();

# Create the test package
eval <<"END_PERL"; die $@ if $@;
package Foo::Bar;

use strict;
use ORLite {
	file   => '$file',
	create => 1,
	tables => 0,
};

1;
END_PERL

