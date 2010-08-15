#!/usr/bin/perl

use strict;
use warnings;
BEGIN {
	$| = 1;
}

use Test::More tests => 2;
use Test::NoWarnings;

use_ok( 'PPI::XS::Tokenizer' );
