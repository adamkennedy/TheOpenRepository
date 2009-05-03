#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
use DBI;
BEGIN {
	unless ( grep { $_ eq 'mysql' } DBI->available_drivers ) {
		plan( skip_all => 'DBI driver mysql is not available' );
	}
	unless ( $ENV{XTRACT_MYSQL_DSN} ) {
		plan( skip_all => 'XTRACT_MYSQL_DSN not provided' );
	}
	unless ( $ENV{XTRACT_MYSQL_USER} ) {
		plan( skip_all => 'XTRACT_MYSQL_USER not provided' );
	}
	unless ( $ENV{XTRACT_MYSQL_PASSWORD} ) {
		plan( skip_all => 'XTRACT_MYSQL_PASSWORD not provided' );
	}
	plan( tests => 10 );
}
use File::Spec::Functions ':ALL';
use File::Remove          'clear';
use Xtract                ();

# Command row data
my @data = (
	[ 1, 'a', 'one'   ],
	[ 2, 'b', 'two'   ],
	[ 3, 'c', 'three' ],
	[ 4, 'd', 'four'  ],
);

# Locate the output database
my $to = catfile('t', 'to');
clear($to);

# Create the Xtract object
my $object = Xtract->new(
	from  => $ENV{XTRACT_MYSQL_DSN},
	user  => $ENV{XTRACT_MYSQL_USER},
	pass  => $ENV{XTRACT_MYSQL_PASSWORD},
	to    => $to,
	index => 1,
	trace => 0,
	argv  => [ ],
);
isa_ok( $object, 'Xtract' );

# Run the extract
ok( $object->run, '->run ok' );

#is_deeply(
#	$publish->dbh->selectall_arrayref('select * from simple3'),
#	\@data,
#	'simple3 data ok',
#);
