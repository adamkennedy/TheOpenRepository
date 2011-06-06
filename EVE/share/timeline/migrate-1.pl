use strict;
use ORLite::Migrate::Patch;

# Create the list of markets we have captured
do(<<'END_SQL') unless table_exists('market');
CREATE TABLE market (
	market_id    TEXT    NOT NULL PRIMARY KEY,
	region_id    INTEGER NOT NULL,
	region_name  TEXT    NOT NULL,
	product_id   INTEGER NOT NULL,
	product_name TEXT    NOT NULL,
	timestamp    TEXT    NOT NULL
)
END_SQL

# Create indexes for the market table
do('CREATE INDEX market__product_name ON market ( product_name )');

# Create the price list table
do(<<'END_SQL') unless table_exists('price');
CREATE TABLE price (
	order_id  INTEGER  NOT NULL PRIMARY KEY,
	market_id TEXT     NOT NULL
		REFERENCES market ( market_id )
		ON DELETE CASCADE,
	system_id  INTEGER NOT NULL,
	station_id INTEGER NOT NULL,
	issued     TEXT    NOT NULL,
	duration   INTEGER NOT NULL,
	bid        INTEGER NOT NULL,
	price      REAL    NOT NULL,
	range      INTEGER NOT NULL,
	entered    INTEGER NOT NULL,
	minimum    INTEGER NOT NULL,
	remaining  INTEGER NOT NULL,
	type_id    INTEGER NOT NULL,
	jumps      INTEGER NOT NULL
)
END_SQL

# Create indexes for the price list table
do('CREATE INDEX price__market_id ON price ( market_id )');
do('CREATE INDEX price__bid ON price ( bid )');
