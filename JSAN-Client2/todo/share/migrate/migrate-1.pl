use strict;
use File::Spec ();
use lib File::Spec->rel2abs(
	File::Spec->catdir(
		File::Spec->updir,
		File::Spec->updir,
		File::Spec->updir,
		File::Spec->updir,
		File::Spec->updir,
	)
);





#####################################################################
# Patch Content

# Create the author table
do(<<'END_SQL');
CREATE TABLE author (
	login VARCHAR(255) PRIMARY KEY,
	name VARCHAR(255),
	doc VARCHAR(255),
	email VARCHAR(255),
	url VARCHAR(255)
)
END_SQL

# Create the distribution table
do(<<'END_SQL');
CREATE TABLE distribution (
	name VARCHAR(255) PRIMARY KEY,
	doc VARCHAR(255)
)
END_SQL

# Create the releases table
do(<<'END_SQL');
CREATE TABLE release (
	id VARCHAR(255) PRIMARY KEY,
	source VARCHAR(255),
	distribution VARCHAR(255),
	author VARCHAR(255),
	version VARCHAR(255),
	created VARCHAR(255),
	doc VARCHAR(255),
	meta VARCHAR(255),
	checksum VARCHAR(255),
	latest VARCHAR(255)
)
END_SQL

# Create the library table
do(<<'END_SQL');
CREATE TABLE library (
	name VARCHAR(255) PRIMARY KEY,
	release VARCHAR(255),
	version VARCHAR(255),
	doc VARCHAR(255)
)
END_SQL

# Create additional indexes
do('CREATE INDEX idx_release_distribution on release ( distribution )');
do('CREATE INDEX idx_release_author on release ( author )');
do('CREATE INDEX idx_library_release on library ( release )');

exit(0);
