package ORDB::CPANTS;

use 5.008005;
use strict;
use warnings;

our $VERSION = '0.01';

use ORLite::Mirror ();

# Don't pull the database for 'require' (so it needs a full 'use' line)
sub import {
	my $class = shift;

	# Prevent double-initialisation
	$class->can('orlite') or
	ORLite::Mirror->import('http://cpants.perl.org/static/cpants_all.db.gz');

	return 1;
}

1;
