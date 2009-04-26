use strict;
use ORLite::Migrate::Patch;

# Create the file metric table
do(<<'END_SQL');
create table file_metric (
	id      integer not null primary key,
	md5     text    not null,
	package text    not null,
	version numeric,
	name    text    not null,
	value   text
)
END_SQL

# Indexes for the main file_metric table
do( 'create index file_metric_md5_idx on file_metric ( md5 )' );
do( 'create index file_metric_package_idx on file_metric ( package )' );
do( 'create unique index file_metric_unique_idx on file_metric ( md5, package, name )' );
