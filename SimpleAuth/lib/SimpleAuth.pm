package SimpleAuth;

use 5.005;
use strict;
use Carp 'croak';
use DBI ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}

use SimpleAuth::Schema  ();
use SimpleAuth::Request ();

my $sqlite_file = '';

sub import {
	my $class = shift;
	if ( @_ ) {
		if ( $sqlite_file ) {
			croak("The SQLite file has already been set");
		}
		unless ( $_[0] and -f $_[0] ) {
			croak("The SQLite file does not exist");
		}
		unless ( -r $_[0] ) {
			croak("The SQLite file is not readable by the CGI user");
		}
		unless ( -w $_[0] ) {
			croak("The SQLite file is not readable by the CGI user");
		}
	}
	$sqlite_file = $_[0];
}

sub sqlite_file {
	$sqlite_file;
}

sub sqlite_dsn {
	'dbi:SQLite:' . shift->sqlite_file;
}

sub sqlite_dbh {
	DBI->connect( shift->sqlite_dsn );
}

sub schema {
	SimpleAuth::Schema->connect( shift->sqlite_dsn );
}

1;
