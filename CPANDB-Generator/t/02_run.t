#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
use URI::file             ();
use File::Spec::Functions ':ALL';
use File::Remove          'clear';
use CPANDB::Generator     ();
BEGIN {
	unless ( $ENV{ADAMK_CHECKOUT} ) {
		plan( skip_all => 'Only run by the author' );
	}
	unless ( $^O eq 'MSWin32' ) {
		plan( skip_all => 'Only runs on Win32' );
	}
}

# Try to find a minicpan
my @minicpan = grep { -d $_ } map { "$_:\\minicpan" } reverse ( 'A' .. 'G' );
unless ( @minicpan ) {
	die("Failed to find a minicpan to test with");
}

# We can (finally) be sure that we can run the test
plan( tests => 2 );

# Create the generator
my $url    = URI::file->new($minicpan[0])->as_string;
my $cpandb = new_ok( 'CPANDB::Generator' => [
        urllist => [ "$url/" ],
] );
clear($cpandb->sqlite);

# Generate the database
ok( $cpandb->run, '->run' );
