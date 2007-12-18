#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
BEGIN {
	unless ( $^O eq 'MSWin32' ) {
		plan( skip_all => 'Not on Win32' );
		exit(0);
	}
	plan( tests => 3 );
}

use File::Spec::Functions ':ALL';
use Perl::Dist::vanilla   ();
use URI::file             ();

sub cpan_uri {
	my $path  = rel2abs( catdir( 't', 'data', 'cpan' ) );
	ok( -d $path, 'Found CPAN directory' );
	ok( -d catdir( $path, 'authors', 'id' ), 'Found id subdirectory' );
	return URI::file->new($path . '\\');
}





#####################################################################
# Constructor Test


my $dist = Perl::Dist::Vanilla->new(
	cpan => cpan_uri(),
);
isa_ok( $dist, 'Perl::Dist::Vanilla' );

1;
