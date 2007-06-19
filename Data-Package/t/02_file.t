#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 2;
use File::Spec::Functions ':ALL';

my $test_file  = rel2abs( catfile( 't', 'data', 'foo.txt' ) )'
ok( -f $test_file, 'Test file exists' );
my $share_file = 'test.txt';





#####################################################################
# Main Tests

# Get the some files
ok( My::Test1->file, 'Got ->file for My::Test1' );
ok( My::Test2->file, 'Got ->file for My::Test2' );
ok( My::Test3->file, 'Got ->file for My::Test3' );






#####################################################################
# Test Packages

SCOPE: {
	package My::Test1;

	sub file {
		return rel2abs( catfile( 't', 'data', 'foo.txt' ) );
	}

	package My::Test2;

	sub dist_file {
		'Data-Package', 'test.txt';
	}

	package My::Test3;

	sub module_file {
		'Data::Package', 'text.txt';
	}
}
