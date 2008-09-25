#!/usr/bin/perl

# Tests database creation, pragmas and versions

use strict;

BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 8;
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

# Test ability to get and set pragmas
is( Foo::Bar->pragma('schema_version' ), 0, 'schema_version is zero' );
is( Foo::Bar->pragma('user_version' ), 0, 'user_version is zero' );
is( Foo::Bar->pragma('user_version', 2 ), 2, 'Set user_version' );
is( Foo::Bar->pragma('user_version' ), 2, 'Confirm user_version changed' );

# Test that the schema_version is updated as expected
ok( Foo::Bar->do('create table foo ( bar int )'), 'Created test table' );
is( Foo::Bar->pragma('schema_version' ), 1, 'schema_version is zero' );
