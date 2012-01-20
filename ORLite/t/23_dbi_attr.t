#!/usr/bin/perl

# Tests for the dbi_attr option (with sqlite_unicode)

BEGIN {
	$|  = 1;
	$^W = 1;
}

use utf8;
use Test::More tests => 6;
use File::Spec::Functions ':ALL';
use t::lib::Test;





#####################################################################
# Set up for testing

# Connect
my $file = test_db();
my $dbh  = create_ok(
	file    => catfile(qw{ t 23_dbi_attr.sql }),
	connect => [ "dbi:SQLite:$file" ],
);

# Create the test package
eval <<"END_PERL"; die $@ if $@;
package TestDB;

use strict;
use ORLite {
	file        => '$file',
    dbi_attr    => {
        PrintError      => 1,
        sqlite_unicode  => 1,
    },
};

1;
END_PERL





#####################################################################
# Tests for changed DBI attrs (incl. sqlite_unicode)

# dbi_attr merged correctly
ok(TestDB->dbh->{PrintError}, 'PrintError has changed');
ok(TestDB->dbh->{RaiseError}, 'RaiseError still has default value');
ok(TestDB->dbh->{sqlite_unicode}, 'new sqlite_unicode value set');

# Loaded correctly
my $smiley = TestDB::Foo->load('smiley');
isa_ok($smiley, 'TestDB::Foo');

# Got right utf smiley
is($smiley->text, '☺', 'right smiley');
