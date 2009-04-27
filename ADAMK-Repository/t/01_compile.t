#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 17;
use Test::NoWarnings;
use Test::Script;

ok( $] >= 5.008, 'Perl version is new enough' );

use_ok( 'ADAMK::Util'                   );
use_ok( 'ADAMK::SVN::Log'               );
use_ok( 'ADAMK::Cache'                  );
use_ok( 'ADAMK::Role::File'             );
use_ok( 'ADAMK::Role::SVN'              );
use_ok( 'ADAMK::Role::Changes'          );
use_ok( 'ADAMK::Role::Make'             );
use_ok( 'ADAMK::Release'                );
use_ok( 'ADAMK::Release::Extract'       );
use_ok( 'ADAMK::Repository'             );
use_ok( 'ADAMK::Distribution'           );
use_ok( 'ADAMK::Distribution::Export'   );
use_ok( 'ADAMK::Distribution::Checkout' );
use_ok( 'ADAMK::Shell'                  );

script_compiles_ok('script/adamk');
