package Xtract::Scan;

use 5.008005;
use strict;
use warnings;
use Carp         ();
use Params::Util ();

our $VERSION = '0.15';

use Mouse 0.93;

has dbh => (
	is  => 'ro',
	isa => 'DBI::db',
);

no Mouse;

sub tables {
	$_[0]->dbh->tables;
}

# Factory method
sub create {
	my $class  = shift;
	my $dbh    = shift;
	my $name   = $dbh->{Driver}->{Name};
	my $driver = Params::Util::_DRIVER("Xtract::Scan::$name", 'Xtract::Scan')
		or Carp::croak('No driver for the database handle');
	$driver->new( dbh => $dbh );
}

1;
