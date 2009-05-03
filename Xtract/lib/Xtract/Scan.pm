package Xtract::Scan;

use 5.008005;
use strict;
use warnings;
use Carp         'croak';
use Params::Util '_DRIVER';

our $VERSION = '0.09';

use Moose 0.73;

has dbh => ( is => 'ro', isa => 'DBI::db' );

no Moose;

sub tables {
	$_[0]->dbh->tables;
}

# Factory method
sub create {
	my $class  = shift;
	my $dbh    = shift;
	my $name   = $dbh->{Driver}->{Name};
	my $driver = _DRIVER("Xtract::Scan::$name", 'Xtract::Scan')
		or croak('No driver for the database handle');
	$driver->new( dbh => $dbh );
}

1;
