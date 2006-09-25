#!/usr/bin/perl -w

# Main testing for Module::Manifest

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 1;
use Module::Manifest ();





#####################################################################
# Load our own MANIFEST file

SCOPE: {
	my $manifest = Module::Manifest->new('MANIFEST');
	isa_ok( $manifest, 'Module::Manifest' );
}

exit(0);
