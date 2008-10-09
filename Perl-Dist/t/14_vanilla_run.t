#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
use LWP::Online ':skip_all';
BEGIN {
	unless ( $^O eq 'MSWin32' ) {
		plan( skip_all => 'Not on Win32' );
		exit(0);
	}
	unless ( $ENV{RELEASE_TESTING} ) {
		plan( skip_all => 'Skipping potentially destructive test' );
		exit(0);
	}
	plan( tests => 2 );
}

use Perl::Dist::Vanilla   ();





#####################################################################
# Constructor Test

my $dist = Perl::Dist::Vanilla->new;
isa_ok( $dist, 'Perl::Dist::Vanilla' );
ok( $dist->run, '->run ok' );
