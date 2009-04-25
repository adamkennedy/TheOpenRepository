package ORDB::CPANTSWeight;

use 5.008005;
use strict;
use warnings;
use ORLite::Mirror 1.20 ();
use ORLite::Mirror 1.12 ();

our $VERSION = '0.01';

use constant ONE_MONTH => 30 * 24 * 60 * 60;

sub import {
	my $class = shift;

	# Prevent double-initialisation
	$class->can('orlite') or
	ORLite::Mirror->import( {
		url    => 'http://svn.ali.as/cpants_weight.db.gz',
		maxage => ONE_MONTH,
	} );

	return 1;
}

1;
