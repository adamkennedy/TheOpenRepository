package ADAMK::Mixin::Trace;

use 5.008;
use strict;
use warnings;
use Exporter ();

use vars qw{$VERSION @EXPORT};
BEGIN {
	$VERSION = '0.07';
	@EXPORT  = 'trace';
}

sub trace {
	$_[0]->{trace}->( @_[1..$#_] ) if $_[0]->{trace};
}

1;
