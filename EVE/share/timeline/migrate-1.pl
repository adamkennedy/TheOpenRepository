use strict;
use ORLite::Migrate::Patch;

# Create the host settings table
do(<<'END_SQL') unless table_exists('price');
CREATE TABLE price (
	order_id INTEGER NOT NULL PRIMARY KEY,
	timestamp VARCHAR(255) NOT NULL,
	region_id INTEGER NOT NULL,
	system_id INTEGER NOT NULL,
	station_id INTEGER NOT NULL,
	product TEXT NOT NULL,
	issued TEXT NOT NULL,
	duration INTEGER NOT NULL,
	bid INTEGER NOT NULL,
	price REAL NOT NULL,
	range INTEGER NOT NULL,
	entered INTEGER NOT NULL,
	minimum INTEGER NOT NULL,
	remaining INTEGER NOT NULL,
	type_id INTEGER NOT NULL,
	jumps INTEGER NOT NULL
)
END_SQL
