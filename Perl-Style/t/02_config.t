#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 2;
use Test::NoWarnings;
use File::Spec          ();
use Perl::Style::Config ();

# Test config
my $file = File::Spec->catfile( 't', '02_config.yml' );
ok( -f $file, 'Found t/02_config.yml' );

# Load the config object
my $config = Perl::Style::Config->load($file);
isa_ok( $config, 'Perl::Style::Config' );
