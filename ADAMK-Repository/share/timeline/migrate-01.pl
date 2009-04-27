use strict;
use ORLite::Migrate::Patch;

# Create the table for caching svn log commands
do(<<'END_SQL');
CREATE TABLE svn (
	id INTEGER NOT NULL PRIMARY KEY,
	directory TEXT,
	command TEXT,
	stdout TEXT
)
END_SQL
do('CREATE INDEX IF NOT EXISTS log__directory ON svn ( directory )');
do('CREATE INDEX IF NOT EXISTS log__command ON svn ( command )');
