package ORDB::CPANRT;

# See CPANRT.pod for docs

use 5.008005;
use strict;
use warnings;
use Params::Util   1.00 ();
use ORLite::Mirror 1.18 ();

our $VERSION = '0.01';

sub import {
	my $class = shift;
	my $param = Params::Util::_HASH(shift) || {};

	# Pass through any params from above
	$param->{url}    ||= 'http://rt.cpan.org/NoAuth/cpan/rtcpan.sqlite.gz';
	$param->{maxage} ||= 24 * 60 * 60; # One day

	# Prevent double-initialisation
	$class->can('orlite') or
	ORLite::Mirror->import($param);

	return 1;
}

1;
