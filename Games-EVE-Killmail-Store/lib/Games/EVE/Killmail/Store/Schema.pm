package Games::EVE::Killmail::Store::Schema;

use 5.005;
use strict;
use base 'DBIx::Class::Schema::Loader';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}

__PACKAGE__->loader_options(
	relationships => 1,
);

1;
