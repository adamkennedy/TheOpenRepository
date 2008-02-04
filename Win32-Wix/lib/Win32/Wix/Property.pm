package Win32::Wix::Property;

# Simple abstraction for a <Property> tag
# This is just a name/value pair.

use strict;

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}

use Object::Tiny qw{
	id
	value
};

1;
