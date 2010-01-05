#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 6;

use_ok( 'Aspect'                      );
use_ok( 'Aspect::Library::Listenable' );
use_ok( 'Aspect::Library::Memoize'    );
use_ok( 'Aspect::Library::Singleton'  );
use_ok( 'Aspect::Library::TestClass'  );
use_ok( 'Aspect::Library::Wormhole'   );
