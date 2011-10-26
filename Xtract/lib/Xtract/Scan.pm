package Xtract::Scan;

use 5.008005;
use strict;
use warnings;
use Carp         ();
use Params::Util ();

our $VERSION = '0.15';





######################################################################
# Class Methods

# Scanner factory
sub create {
	my $class  = shift;
	my $dbh    = shift;
	my $name   = $dbh->{Driver}->{Name};
	my $driver = Params::Util::_DRIVER("Xtract::Scan::$name", 'Xtract::Scan')
		or Carp::croak('No driver for the database handle');
	$driver->new( dbh => $dbh );
}





######################################################################
# Constructor and Accessors

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Check params
	unless ( Params::Util::_INSTANCE($self->dbh, 'DBI::db') ) {
		Carp::croak("Param 'dbh' is not a 'DBI::db' object");
	}

	return $self;
}

sub dbh {
	$_[0]->{dbh};
}





######################################################################
# Database Introspection

sub tables {
	$_[0]->dbh->tables;
}

sub columns {
	$_[0]->dbh->column_info
}




######################################################################
# SQL Fragments

sub sql_columns {

}

1;
