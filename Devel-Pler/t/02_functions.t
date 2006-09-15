#!/usr/bin/perl -w

# Test specific functions in Devel::Pler

use strict;
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
}

use Test::More tests => 4;
use Devel::Pler;

# Can we find the current perl executable ok
ok( perl(), 'Found perl() ok' );
ok( perl,   'Found perl   ok' );

# Can we find the mandated make
ok( make(), 'Found make() ok' );
ok( make,   'Found make   ok' );

exit(0);
