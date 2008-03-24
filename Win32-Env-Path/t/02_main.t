#!/usr/bin/perl

use strict;
use warnings;
BEGIN {
	$| = 1;
}

use Test::More tests => 6;
use Win32::Env::Path;





#####################################################################
# Object Creation

SCOPE: {
	my $path = Win32::Env::Path->new;
	isa_ok( $path, 'Win32::Env::Path' );
	is( $path->name, 'PATH', '->name ok' );
	is( $path->autosave, 1, '->autosave is true by default' );
	is( $path->user,   ! 1, '->user is false by default' );
	ok( defined($path->value), '->string exists' );
	is( ref($path->array), 'ARRAY', '->array exists' );

	# Check the real path of something
	my $spec = $path->resolve( $path->array->[0] );

	# Clean the path
	$path->clean;
}

1;
