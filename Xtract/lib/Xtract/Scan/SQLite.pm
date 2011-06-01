package Xtract::Scan::SQLite;

use 5.008005;
use strict;
use warnings;

our $VERSION = '0.15';

use Mouse 0.93;

extends 'Xtract::Scan';

override tables => sub {
	grep {
		! /^sqlite_/
	} map {
		/"([^\"]+)"$/ ? "$1" : $_
	} super();
};

no Mouse;

1;
