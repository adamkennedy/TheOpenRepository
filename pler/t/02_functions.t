#!/usr/bin/perl -w

# Test specific functions in Devel::Pler

use strict;
use File::Spec::Functions ':ALL';
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 8;
use pler;

# Can we find the current perl executable ok
ok( perl(), 'Got perl() ok' );
ok( perl,   'Got perl   ok' );
ok( -f perl, 'perl exists'  );
ok( file_name_is_absolute( perl ), 'perl path is absolute' );

# Can we find the mandated make
ok( make(), 'Got make() ok' );
ok( make,   'Got make   ok' );
ok( -f make, 'make exists'  );
ok( file_name_is_absolute( make ), 'make path is absolute' );

exit(0);
