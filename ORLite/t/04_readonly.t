#!/usr/bin/perl

# Tests both readonly functionality and version locking.

use strict;

BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 7;
use File::Spec::Functions ':ALL';
use t::lib::Test;

SCOPE: {
	# Test file
	my $file = test_db();

	# Connect
	my $dbh = connect_ok("dbi:SQLite:$file");
	$dbh->begin_work;
	$dbh->rollback;
	ok( $dbh->disconnect, 'disconnect' );
}

# Set up again
my $file = test_db();
my $dbh  = create_ok(
	file         => catfile(qw{ t 02_basics.sql }),
	connect      => [ "dbi:SQLite:$file" ],
	user_version => 10,
);

# Create the test package
eval <<"END_PERL"; die $@ if $@;
package Foo::Bar;

use strict;
use ORLite {
	file         => '$file',
	readonly     => 1,
	user_version => 10,
};

1;
END_PERL

# Check the user_version value
is( Foo::Bar->pragma('user_version'), 10, '->user_version ok' );

# Check the ->count method
is( Foo::Bar::TableOne->count, 0, 'Found 0 rows' );

# There's some things we shouldn't be able to do
ok( ! Foo::Bar->can('commit'), 'No transaction support' );
ok( ! Foo::Bar::TableOne->can('create'), 'Cant create object' );
