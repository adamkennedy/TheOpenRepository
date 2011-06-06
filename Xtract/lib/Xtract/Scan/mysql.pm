package Xtract::Scan::mysql;

use 5.008005;
use strict;
use Xtract::Scan ();

our $VERSION = '0.15';
our @ISA     = 'Xtract::Scan';





######################################################################
# Introspection Methods

sub tables {
	map {
		/`([^`]+)`$/ ? "$1" : $_
	} $_[0]->dbh->tables;
};

1;
