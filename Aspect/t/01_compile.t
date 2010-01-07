#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 4;

use_ok( 'Aspect'                      );
use_ok( 'Aspect::Library::Listenable' );
use_ok( 'Aspect::Library::Singleton'  );
use_ok( 'Aspect::Library::Wormhole'   );
