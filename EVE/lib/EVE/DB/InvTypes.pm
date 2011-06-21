package EVE::DB::InvTypes;

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

	# This should be a name of a product
	my @types = $class->select('where typeName = ?', $key);
	unless ( @types == 1 ) {
		Carp::croak("Failed to find type '$key'");
	}
	return $types[0];
}

1;
