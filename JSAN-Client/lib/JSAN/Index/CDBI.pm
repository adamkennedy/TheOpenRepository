package JSAN::Index::CDBI;

# The JSAN::Index::CDBI class acts as a base class for the index and provides
# the integration with Class::DBI and JSAN::Transport
#
# It has no user-servicable parts at this time

use strict;
use JSAN::Transport ();
use base 'Class::DBI';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.12';
}

my $dbh;

sub db_Main {
	$dbh or
	$dbh = JSAN::Transport->index_dbh;
}

1;
