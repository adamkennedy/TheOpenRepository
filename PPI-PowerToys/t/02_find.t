#!/usr/bin/perl

# Compile-testing for Perl::PowerToys

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 4;
use PPI::App::ppi_version ();

sub version_is {
        my $string = shift;
        my $version = shift;
        my $message = shift || "Found version $version";

}


ok(1);

