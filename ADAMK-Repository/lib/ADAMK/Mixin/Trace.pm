package ADAMK::Mixin::Trace;

use 5.008;
use strict;
use warnings;
use Exporter     ();
use Params::Util ();

use vars qw{$VERSION @EXPORT};
BEGIN {
	$VERSION = '0.07';
	@EXPORT  = 'trace';
}

sub trace {
	if ( Params::Util::_CODE($_[0]->{trace}) ) {
		$_[0]->trace( @_[1..$#_] );
	} elsif ( $_[0]->{trace} ) {
		print @_[1..$#_];
	}
}

1;
