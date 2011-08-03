package ORDB::CPANUploads;

use 5.008005;
use strict;
use warnings;
use Params::Util   1.00 ();
use ORLite::Mirror 1.20 ();

our $VERSION = '1.07';

sub import {
	my $class  = shift;
	my $params = Params::Util::_HASH(shift) || {};

	# Pass through any params from above
	$params->{url}    ||= 'http://devel.cpantesters.org/uploads/uploads.db.bz2';
	$params->{maxage} ||= 7 * 24 * 60 * 60; # One week

	# Prevent double-initialisation
	$class->can('orlite') or
	ORLite::Mirror->import( $params );

	return 1;
}

sub age {
	my $class = shift;

	# Find the most recent upload
	my @latest = ORDB::CPANUploads::Uploads->select(
		'ORDER BY released DESC LIMIT 1',
	);
	unless ( @latest == 1 ) {
		die "Unexpected number of uploads";
	}

	# Compare to the current time
	return time - $latest[0]->released;
}

1;
