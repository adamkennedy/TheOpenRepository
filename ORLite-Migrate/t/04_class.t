#!/usr/bin/perl

BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 3;
use File::Spec::Functions ':ALL';
use ORLite::Migrate::Class ();
use t::lib::Test;
use t::lib::MyTimeline;

# Set up the file
my $file = test_db();

# Create the test package
eval <<"END_PERL"; die $@ if $@;
package Foo::Bar;

use strict;
use ORLite::Migrate {
	file     => '$file',
	create   => 1,
	tables   => 0,
	prune    => 1,
	timeline => 't::lib::MyTimeline',
};

1;
END_PERL
