package EVE::DB::MapRegions;

use strict;
use Carp         ();
use Params::Util ();
use EVE::DB      ();

our $VERSION = '0.01';

sub load {
	my $class = shift;
	my $key   = shift;
	if ( Params::Util::_POSINT($key) ) {
		return $class->SUPER::load($key);
	}

	# This should be a name of a region
	my @regions = $class->select('where regionName = ?', $key);
	unless ( @regions == 1 ) {
		Carp::croak("Failed to find region '$key'");
	}
	return $regions[0];
}

1;
