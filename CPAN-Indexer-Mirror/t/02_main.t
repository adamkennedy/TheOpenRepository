#!/usr/bin/perl

BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 5;
use File::Spec::Functions ':ALL';
use File::Remove 'clear';
use CPAN::Indexer::Mirror ();

my $root = catdir( 't', 'data' );
ok( -d $root, 'Found the root dir' );
clear( catfile( $root, 'mirror.yml'  ) );
clear( catfile( $root, 'mirror.json' ) );

my $indexer = CPAN::Indexer::Mirror->new( root => $root );
isa_ok( $indexer, 'CPAN::Indexer::Mirror' );
ok( $indexer->run, '->run ok' );
ok( -f catfile( $root, 'mirror.yml'  ), 'Created mirror.yml'  );
ok( -f catfile( $root, 'mirror.json' ), 'Created mirror.json' );
