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

use Test::More tests => 4;
use File::Find::Rule       ();
use File::Find::Rule::Perl ();
use constant FFR => 'File::Find::Rule';

# Check the methods are added
ok( FFR->can('ignore_vcs'), '->ignore_vcs method exists' );
ok( FFR->can('ignore_cvs'), '->ignore_cvs method exists' );
ok( FFR->can('ignore_svn'), '->ignore_svn method exists' );

# Make an object containing all of them
my $Rule = File::Find::Rule->new->ignore_cvs->ignore_svn;
isa_ok( $Rule, 'File::Find::Rule' );

exit(0);
