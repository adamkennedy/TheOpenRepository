#!/usr/bin/perl

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
use Padre::DB::Patch;





#####################################################################
# Patch Content

# Create the author_weight table
do(<<'END_SQL');
create table author_weight (
	id         integer      not null primary key,
	pauseid    varchar(255) not null unique
)
END_SQL

# Create the dist_weight table
do(<<'END_SQL');
create table dist_weight (
	id               integer      not null primary key,
	dist             varchar(255) not null unique,
	author           integer      not null,
	weight           integer          null,
	volatility       integer          null,
	enemy_downstream integer      not null,
	debian_candidate integer      not null
)
END_SQL

exit(0);
