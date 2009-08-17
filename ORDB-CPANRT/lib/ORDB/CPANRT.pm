package ORDB::CPANRT;

use 5.008005;
use strict;
use warnings;
use Params::Util   1.00 ();
use ORLite::Mirror 1.16 ();

our $VERSION = '0.01';

sub import {
	my $class = shift;
	my $params = Params::Util::_HASH(shift) || {};

	# Pass through any params from above
	$params->{url}    ||= 'http://rt.cpan.org/NoAuth/cpan/rtcpan.sqlite.gz';
	$params->{maxage} ||= 24 * 60 * 60; # One day

	# Prevent double-initialisation
	$class->can('orlite') or
	ORLite::Mirror->import( $params );

	return 1;
}

1;
