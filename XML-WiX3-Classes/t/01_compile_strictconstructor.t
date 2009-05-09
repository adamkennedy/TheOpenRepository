use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

{
	package Test;
	use Moose 0.74;
	use Test::More tests => 1;

	# XML::WiX3::Classes::StrictConstructor needs to be used within 
	# a Moose class in order to work right.
	use_ok('XML::WiX3::Classes::StrictConstructor');
}

1;