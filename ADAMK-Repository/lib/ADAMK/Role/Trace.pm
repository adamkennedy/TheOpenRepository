package ADAMK::Role::Trace;

use 5.008;
use strict;
use warnings;
use Params::Util      ();
use ADAMK::Repository ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.11';
}

sub trace {
	if ( Params::Util::_CODE($_[0]->{trace}) ) {
		$_[0]->trace( @_[1..$#_] );
	} elsif ( $_[0]->{trace} ) {
		print @_[1..$#_];
	}
}

1;
