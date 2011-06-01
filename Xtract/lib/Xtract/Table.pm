package Xtract::Table;

# Object that represents a single table in the destination database.

use 5.008005;
use strict;
use warnings;

our $VERSION = '0.15';

use Mouse;

has name => {
	is  => 'ro',
	isa => 'Str',
};

no Mouse;

1;
