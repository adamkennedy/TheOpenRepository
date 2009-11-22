package Xtract::Scan::SQLite;

use 5.008005;
use strict;
use warnings;

our $VERSION = '0.12';

use Moose 0.73;

extends 'Xtract::Scan';

override tables => sub {
	grep {
		! /^sqlite_/
	} map {
		/"([^\"]+)"$/ ? "$1" : $_
	} super();
};

no Moose;

1;
