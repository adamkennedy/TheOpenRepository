package SMS::Send::BAD5;

use strict;
use base 'SMS::Send::Driver';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}

# Return something other than a driver object
sub new { bless {}, 'Foo' }

1;
