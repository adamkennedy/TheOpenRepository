package Xtract::Scan::mysql;

use 5.008005;
use strict;
use warnings;

our $VERSION = '0.14';

use Mouse 0.93;

extends 'Xtract::Scan';

override tables => sub {
	map {
		/`([^`]+)`$/ ? "$1" : $_
	} super();
};

no Mouse;

1;
