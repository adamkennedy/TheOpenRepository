package Games::EVE::Killmail::Store;

use 5.005;
use strict;
use Carp                                ();
use Params::Util                        qw{ _INSTANCE };
use DBIx::Class                         ();
use DBIx::Class::Schema::Loader         ();
use DBIx::Class::Schema::Loader::SQLite ();
use Games::EVE::Killmail::Store::Schema ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}





#####################################################################
# Data Location

my $FILE = undef;
my $DSN  = undef;

sub import {
	return unless defined $_[0];

	# You can't change the location
	if ( defined $FILE ) {
		return if $FILE eq $_[0];
		Carp::croak("SQLite location is already set and cannot be changed");
	}

	# Should be a file that exists
	unless ( -f $_[0] ) {
		Carp::croak("SQLite file '$FILE' does not exist");
	}

	$FILE = $_[0];
	$DSN  = "dbi:SQLite:$FILE";
}

sub dsn {
	return $DSN;
}

sub dbh {
	my $class = shift;
	my $dsn   = $class->dsn or Carp::croak("SQLite DSN has not been set");

	my $dbh = DBI->connect( $dsn );
	unless ( _INSTANCE($dbh, 'DBI::db') ) {
		Carp::croak("Failed to create connection to $dsn");
	}

	return $dbh;
}

sub schema {
	my $class  = shift;
	my $dsn   = $class->dsn or Carp::croak("SQLite DSN has not been set");

	# Create the schema
	my $schema = Games::EVE::Killmail::Store::Schema->connect( $dsn );
	unless ( _INSTANCE($schema, 'Something') ) {
		Carp::croak("Failed to create connection to $dsn");
	}

	return $schema;
}

1;
