#!/usr/bin/perl

# Allow people debugging to walk down into the generation code
BEGIN {
	$DB::single = 1;
}

# Create an ORM model on the CPANTS database.
# Mirror the data and generate the classes.
use ORLite::Mirror {
	url     => 'http://cpants.perl.org/static/cpants_all.db.gz',
	package => 'CPANTS',
};

1;
