#!/usr/bin/perl

# Tests database creation

use strict;

BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 3;
use File::Spec::Functions ':ALL';
use t::lib::Test;

# Set up the file
my $file = test_db();

# Create the test package
eval <<"END_PERL"; die $@ if $@;
package Foo::Bar;

use strict;
use ORLite {
	file   => '$file',
	create => 1,
	tables => 0,
};

1;
END_PERL

ok( Foo::Bar->can('connect'), 'Created read code'  );
ok( Foo::Bar->can('begin'),   'Created write code' );
is( Foo::Bar->pragma('user_version'), 0, 'user_version is zero' );
