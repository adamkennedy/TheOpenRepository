#!/usr/bin/perl

# Tests for the unicode option

BEGIN {
	$|  = 1;
	$^W = 1;
}
use Test::More;

BEGIN {
	# Tests won't succeed before 5.8.5
	if ( $] < 5.008005 ) {
		plan skip_all => 'Perl 5.8.5 or above required.';
	}
}

use utf8;
use File::Spec::Functions ':ALL';
use t::lib::Test;





#####################################################################
# Set up for testing

plan tests => 3;

# Connect
my $file = test_db();
my $dbh  = create_ok(
	file    => catfile(qw{ t 23_unicode.sql }),
	connect => [ "dbi:SQLite:$file" ],
);

# Create the test package
eval <<"END_PERL"; die $@ if $@;
package TestDB;

use strict;
use ORLite {
	file	=> '$file',
	unicode	=> 1,
};

1;
END_PERL





#####################################################################
# Tests for the unicode option

# Loaded correctly
my $smiley = TestDB::Foo->load('smiley');
isa_ok($smiley, 'TestDB::Foo');

# Got right utf8 smiley without explicit decode
is($smiley->text, '☺', 'right smiley');
