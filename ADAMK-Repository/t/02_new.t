#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
if ( $ENV{ADAMK_CHECKOUT} ) {
	plan( tests => 1005 );
} else {
	plan( skip_all => '$ENV{ADAMK_CHECKOUT} is not defined' );
}

use ADAMK::Repository;

my $root = $ENV{ADAMK_CHECKOUT};






#####################################################################
# Simple Constructor

my $repository = ADAMK::Repository->new( root => $root );
isa_ok( $repository, 'ADAMK::Repository' );
is( $repository->root, $root, '->root ok' );





#####################################################################
# SVN Methods

my $hash = $repository->svn_info( $repository->root );
is( ref($hash), 'HASH', '->svn_info' );
is(
	$hash->{RepositoryRoot},
	'http://svn.ali.as/cpan',
	'svn_info: Repository Root ok',
);
is(
	$hash->{RepositoryUUID},
	'88f4d9cd-8a04-0410-9d60-8f63309c3137',
	'svn_info: Repository UUID ok',
);
is(
	$hash->{NodeKind},
	'directory',
	'svn_info: Node Kind ok',
);





#####################################################################
# Release Methods

my $expected = 998;
my @releases = $repository->releases;
ok( scalar(@releases) >= $expected, 'Found a bunch of releases' );
foreach ( 0 .. $expected - 1 ) {
	isa_ok( $releases[$_], 'ADAMK::Release', "Release $_" );
}
