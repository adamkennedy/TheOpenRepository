package ORLite::Migrate::Class;

=pod

=head1 NAME

ORLite::Migrate::Class - ORLite::Migrate timelines contained in a single class

=head1 SYNOPSIS

  package My::Timeline;
  
  use strict;
  use base 'ORLite::Migrate::Class';
  
  sub upgrade1 {
      my $self = shift;
      $self->do('CREATE TABLE foo ( bar integer not null primary key )');
  }
  
  1;

=head1 DESCRIPTION

The default L<ORLite::Migrate> timeline implementation makes use of separate
Perl "patch" scripts to move the database schema timeline forwards.

This solution is prefered because the separate scripts provide process
isolation between your migration and run-time code. That is, the code that
migrates the schema a single step forwards is guarenteed to never use the same
variables or load the same modules or interact strangely with any other patch
scripts, or with the main program.

However, to execute a sub-script your program needs to reliably know where the
Perl executable that launched it is and in some situations this is difficult or
infeasible.

B<ORLite::Migrate::Class> provides an alternative mechanism for specifying the
migration timeline which adds the ability to run migration timelines in strange
Perl environments at the cost of losing process isolation for your patch code.

When using this method, extra caution should be taken to avoid all use of global
variables, and to strictly avoid loading large amounts of data into memory or
using magic Perl modules such as L<Aspect> or L<UNIVERSAL::isa> which might
have a global impact on your program.

To use this method, create a new class which inherits from
L<ORLite::Migrate::Class> and create a C<upgrade1> method. When encountering
a new unversioned SQLite database, the migration planner will execute this
C<upgrade1> method and set the schema version to 1 once completed.

To make further changes to the schema, you add additional C<upgrade2>,
C<upgrade3> and so on.

=head1 METHODS

A series of convenience methods are provided for you by the base class to
assist in making your schema patch code simpler and easier.

=cut

use 5.008005;
use strict;
use warnings;
use DBI          ();
use DBD::SQLite  ();
use Params::Util ();

our $VERSION = '1.08';





######################################################################
# Constructor

=pod

=head2 new

  my $timeline = My::Class->new(
      dbh => $DBI_db_object,
  );

The C<new> method is called internally by L<ORLite::Migrate> on the timeline
class you specify to construct the timeline object.

The constructor takes a single parameter which should be a L<DBI::db>
database connection to your SQLite database.

Returns an instance of your timeline class, or throws an exception (dies) if
not passed a DBI connection object, or the database handle is not C<AutoCommit>.

=cut

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Check the database handle
	unless ( Params::Util::_INSTANCE( $self->dbh, 'DBI::db' ) ) {
		die "Missing or invalid dbh database handle";
	}
	unless ( $self->dbh->{AutoCommit} ) {
		die "Database connection must be AutoCommit";
	}

	return $self;
}





#######################################################################
# Internal Methods

sub upgrade {
	my $self = shift;
	my $want = Params::Util::_POSINT(shift);
	my $have = $self->user_version;

	# Roll the schema forwards
	while ( $want and $want > $have ) {

		# Find the migration step
		my $method = "upgrade" . ++$have;
		unless ( $self->can($method) ) {
			die "No migration path to user_version $want";
		}

		# Run the migration step
		unless ( eval { $self->$method } ) {
			die "Schema migration failed during $method: $@";
		}

		# Confirm completion
		$self->user_version($have);
	}

	return 1;
}





######################################################################
# Support Methods

=pod

=head2 dbh

If you need to do something to the database outside the scope of the methods
described below, the C<dbh> method can be used to get access to the database
connection directly.

This is discouraged as it can allow your migration code to create changes that
might cause unexpected problems. However, in the 1% of cases where the methods
below are not enough, using it with caution will allow you to make changes that
would not otherwise be possible.

=cut

sub dbh {
	$_[0]->{dbh};
}

sub do {
	shift->dbh->do(@_);
}

sub selectall_arrayref {
	shift->dbh->selectall_arrayref(@_);
}

sub selectall_hashref {
	shift->dbh->selectall_hashref(@_);
}

sub selectcol_arrayref {
	shift->dbh->selectcol_arrayref(@_);
}

sub selectrow_array {
	shift->dbh->selectrow_array(@_);
}

sub selectrow_arrayref {
	shift->dbh->selectrow_arrayref(@_);
}

sub selectrow_hashref {
	shift->dbh->selectrow_hashref(@_);
}

sub user_version {
	shift->pragma( 'user_version', @_ );
}

sub pragma {
	$_[0]->do("pragma $_[1] = $_[2]") if @_ > 2;
	$_[0]->selectrow_arrayref("pragma $_[1]")->[0];
}

sub table_exists {
	$_[0]->selectrow_array(
		"select count(*) from sqlite_master where type = 'table' and name = ?",
		{}, $_[1],
	);
}

sub column_exists {
	$_[0]->table_exists( $_[1] )
		or $_[0]->selectrow_array( "select count($_[2]) from $_[1]", {} );
}

1;

# Copyright 2008-2011 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.

