#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 3;

use File::Spec::Functions ':ALL';
use Perl::Dist::Bootstrap ();
use URI::file             ();

sub cpan_uri {
	my $path  = rel2abs( catdir( 't', 'data', 'cpan' ) );
	ok( -d $path, 'Found CPAN directory' );
	ok( -d catdir( $path, 'id' ), 'Found id subdirectory' );
	return URI::file->new($path . '\\');
}





#####################################################################
# Constructor Test


my $dist = Perl::Dist::Bootstrap->new(
	cpan_uri => cpan_uri(),
);
isa_ok( $dist, 'Perl::Dist::Bootstrap' );

1;
