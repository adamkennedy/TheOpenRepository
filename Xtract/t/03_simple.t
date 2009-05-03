#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 19;
use File::Spec::Functions ':ALL';
use File::Remove          'clear';
use Xtract;

# Prepare
my $from = catfile('t', 'data', 'Foo-Bar.sqlite');
my $to   = catfile('t', 'to');
ok( -f $from, 'Found --from file' );
clear($to, "$to.gz", "$to.bz2", "$to.lz");
ok( ! -f $to, 'Cleared --to file' );





#####################################################################
# Basic Constructor

my $dsn = "DBI:SQLite:$from";
SCOPE: {
	# Constructor call
	my $object = Xtract->new(
		from  => $dsn,
		user  => '',
		pass  => '',
		to    => $to,
		index => 1,
		argv  => [ ],
	);
	isa_ok( $object, 'Xtract' );
	is( $object->from,  $dsn, '->from ok'  );
	is( $object->user,  '',   '->user ok'  );
	is( $object->pass,  '',   '->pass ok'  );
	is( $object->to,    $to,  '->to ok'    );
	is( $object->index, 1,    '->index ok' );
	is( $object->sqlite_cache, undef, '->sqlite_cache ok' );
	is( ref($object->argv), 'ARRAY', '->argv ok' );

	# Other accessors
	is( $object->to_gz,  "$to.gz",  '->to_gz ok'  );
	is( $object->to_bz2, "$to.bz2", '->to_bz2 ok' );
	SKIP: {
		unless ( defined $object->to_lz ) {
			skip("LZMA support not available", 1);
		}
		is( $object->to_lz, "$to.lz", '->to_lz ok' );
	}

	# Get the list of tables
	is_deeply(
		[ $object->from_tables ],
		[ 'table_one' ],
		'->tables ok',
	);

	# Run the extraction
	ok( $object->run, '->run ok' );

	# Did we create the files we expected?
	ok( -f $object->to,     "Created " . $object->to     );
	ok( -f $object->to_gz,  "Created " . $object->to_gz  );
	ok( -f $object->to_bz2, "Created " . $object->to_bz2 );
	SKIP: {
		unless ( defined $object->to_lz ) {
			skip("LZMA support not available", 1);
		}
		ok( -f $object->to_lz,  "Created " . $object->to_lz  );
	}

}
