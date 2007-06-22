package Games::EVE::Killmail::Store;

use 5.005;
use strict;
use Carp         ();
use Params::Util qw{ _INSTANCE _STRING };
use DBIx::Class  ();
use Games::EVE::Killmail::Store::Schema ();

use base 'Class::Default';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}





#####################################################################
# Data Location and Constructor

my $FILE = undef;

sub import {
	return unless defined $_[0];

	# You can't change the location
	if ( defined $FILE ) {
		return if $FILE eq $_[0];
		Carp::croak("SQLite location is already set and cannot be changed");
	}

	$FILE = $_[0];
}

sub _create_default_object {
	my $class = shift;
	unless ( $FILE ) {
		Carp::croak("Default SQLite file has not been set");
	}
	return $class->new( $FILE );
}

sub new {
	my $class = shift;
	my $file  = shift;

	# Should be a file that exists
	unless ( $file ) {
		Carp::croak("Did not provide a SQLite file name");
	}
	unless ( -f $file ) {
		Carp::croak("SQLite file '$FILE' does not exist");
	}

	# Create the object
	my $self = bless {
		file   => $file,
		dsn    => "dbi:SQLite:$file",
		schema => undef,
		}, $class;

	# Create the schema
	$self->{schema} = Games::EVE::Killmail::Store::Schema->connect($self->dsn)
		or Carp::croak("Failed to create schema for $file");

	$self;
}

sub file {
	my $self = shift->_self;
	return $self->{file};
}

sub dsn {
	my $self = shift->_self;
	return $self->{dsn};
}

sub schema {
	my $self = shift->_self;
	return $self->{schema};
}

sub resultset {
	my $self = shift->_self;
	my $name = defined _STRING($_[0]) ? shift : 'Killmail';
	return $self->schema->resultset($name);
}

1;
