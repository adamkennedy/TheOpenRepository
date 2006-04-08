#!/usr/bin/perl -w

# Testing for File::Find::Rule::Perl

use strict;
use lib ();
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	unless ( $ENV{HARNESS_ACTIVE} ) {
		require FindBin;
		$FindBin::Bin = $FindBin::Bin; # Avoid a warning
		chdir catdir( $FindBin::Bin, updir() );
		lib->import(
			catdir('blib', 'arch'),
			catdir('blib', 'lib' ),
			catdir('lib'),
			);
	}
}

use Test::More tests => 6;
use File::Find::Rule       ();
use File::Find::Rule::Perl ();
use constant FFR => 'File::Find::Rule';

# Check the methods are added
foreach my $method ( qw{ perl_file perl_module perl_script perl_test perl_installer } ) {
	ok( FFR->can($method), "->$method exists" );
}

# Make an object containing all of them
my $Rule = File::Find::Rule->new->perl_file;
isa_ok( $Rule, 'File::Find::Rule' );

exit(0);
