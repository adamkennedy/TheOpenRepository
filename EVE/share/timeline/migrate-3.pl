use strict;
use ORLite::Migrate::Patch;

# Create the my_order table
do(<<'END_SQL') unless table_exists('asset');
CREATE TABLE asset (
	item_id     INTEGER NOT NULL PRIMARY KEY,
	location_id INTEGER NOT NULL,
	type_id     INTEGER NOT NULL,
	quantity    INTEGER NOT NULL,
	singleton   INTEGER NOT NULL,
	flag        INTEGER NOT NULL
)
END_SQL
