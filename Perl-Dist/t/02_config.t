#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 2;
use Test::Script;
use File::Spec::Functions ':ALL';
use Perl::Dist::Builder;

my $vanilla = catfile( 't', 'data', 'vanilla.yml' );
ok( -f $vanilla, 'Found test config' );

my $object = Perl::Dist::Builder->new( $vanilla );
isa_ok( $object, 'Perl::Dist::Builder' );
