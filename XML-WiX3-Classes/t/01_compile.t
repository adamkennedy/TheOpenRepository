use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
use Test::UseAllModules;

# XML::WiX3::Classes::StrictConstructor needs to be used within 
# a Moose class in order to work right.
# We'll test it later.
all_uses_ok(except => qw(XML::WiX3::Classes::StrictConstructor));

END {
	diag( "Testing XML::WiX3::Classes $XML::WiX3::Classes::VERSION" );
}