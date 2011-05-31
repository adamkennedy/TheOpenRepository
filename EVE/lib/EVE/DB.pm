package EVE::DB;

use 5.008;
use strict;
use warnings;
use ORLite::Mirror 1.21 {
	url           => 'http://eve.no-ip.de/inc15/inc15-sqlite3-v1.db.bz2',
	show_progress => 1,
	maxage        => 999999999999,
};

our $VERSION = '0.01';

1;
