use strict;
use ORLite::Migrate::Patch;

# Create the my_order table
do(<<'END_SQL') unless table_exists('my_order');
CREATE TABLE my_order (
	order_id     INTEGER  NOT NULL PRIMARY KEY,
	account_id   INTEGER NOT NULL,
	char_id      INTEGER NOT NULL,
	char_name    TEXT NOT NULL,
	region_id    INTEGER NOT NULL,
	region_name  TEXT    NOT NULL,
	system_id    INTEGER NOT NULL,
	system_name  TEXT NOT NULL,
	station_id   INTEGER NOT NULL,
	station_name INTEGER NOT NULL,
	type_id      INTEGER NOT NULL,
	duration     INTEGER NOT NULL,
	bid          INTEGER NOT NULL,
	price        REAL    NOT NULL,
	range        INTEGER NOT NULL,
	entered      INTEGER NOT NULL,
	minimum      INTEGER NOT NULL,
	remaining    INTEGER NOT NULL,
	is_corp      INTEGER NOT NULL,
	contraband   INTEGER NOT NULL,
	escrow       REAL NOT NULL,
	timestamp    TEXT    NOT NULL
)
END_SQL
