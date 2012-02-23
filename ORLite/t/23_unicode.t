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

plan tests => 6;

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
my $smiley = TestDB::Foo->load(1);
isa_ok($smiley, 'TestDB::Foo');

# Check that the is_utf8 flags are set as expected
ok( ! utf8::is_utf8($smiley->id), '->id is not utf8' );
ok( utf8::is_utf8($smiley->name), '->name is utf8' );
ok( utf8::is_utf8($smiley->text), '->text is utf8' );
is($smiley->text, '☺', 'right smiley');
