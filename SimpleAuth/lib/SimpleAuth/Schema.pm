package SimpleAuth::DB;

use 5.005;
use strict;
use base 'DBIx::Class::Schema';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}

__PACKAGE__->load_classes;

1;
