package ADAMK::LogEntry;

use 5.008;
use strict;
use warnings;

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.11';
}

use Object::Tiny::XS qw{
	author
	date
	message
	revision
};

1;
