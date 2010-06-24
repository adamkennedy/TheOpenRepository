#!/usr/bin/perl

use strict;
BEGIN {
	$| = 1;
	$^W = 1;
}

use Test::More tests => 3;
use Test::NoWarnings;

use_ok( 'Wx::Perl::FormBuilder' );
use_ok( 'Padre::FormBuilder'    );
