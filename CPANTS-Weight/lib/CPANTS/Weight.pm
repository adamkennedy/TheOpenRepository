package CPANTS::Weight;

=pod

=head1 NAME

CPANTS::Weight - Graph based weights for CPAN Distributions

=head1 DESCRIPTION

C<CPAN::Weight> is a module that consumes the CPANTS database, and
generates a variety of graph-based weighting values for the distributions,
producing a SQLite database of the weighting data, for use in higher-level
applications that work with the CPANTS data.

=head1 METHODS

=cut

use 5.008;
use strict;
use warnings;
use File::Spec                            ();
use File::HomeDir                         ();
use Algorithm::Dependency 1.108           ();
use Algorithm::Dependency::Weight         ();
use Algorithm::Dependency::Source::DBI    ();
use Algorithm::Dependency::Source::Invert ();

our $VERSION = '0.01';

# Generate the class tree
use ORLite 1.19 {
	file => File::Spec->catfile(
		File::HomeDir->my_data,
		($^O eq 'MSWin32' ? 'Perl' : '.perl'),
		'CPANTS-Weight',
		'CPANTS-Weight.sqlite',
	),
	create => sub {
		$_[0]->do(<<'END_SQL');
create table author_weight (
	id         integer      not null primary key,
	pauseid    varchar(255) not null unique
);
END_SQL

		$_[0]->do(<<'END_SQL');
create table dist_weight (
	id         integer      not null primary key,
	dist       varchar(255) not null unique,
	author     integer      not null,
	weight     integer          null,
	volatility integer          null
)
END_SQL
	},
	user_version => 0,
};

# Load the CPANTS database (This could take a while...)
use ORDB::CPANTS;

# Common string fragments
my $SELECT_IDS     = <<'END_SQL';
select
	id
from
	dist
where
	id > 0
END_SQL

my $SELECT_DEPENDS = <<'END_SQL';
select
	dist,
	in_dist
from
	prereq
where
	in_dist is not null
	and
	dist > 0
	and
	in_dist > 0
END_SQL





#####################################################################
# Main Method

=pod

=head2 run

  CPANTS::Weight->run;

The main C<run> method does a complete generation cycle for the CPANTS
weighting database. It will retrieve the CPANTS data (if needed) calculate
the weights, and then (re)populate the CPANTS-Weight.sqlite database.

Once completed, the C<CPANTS::Weight-E<gt>sqlite> method can be used to
locate the completed SQLite database file.

=cut

sub run {
	my $class = shift;

	# Skip if the output database is newer than the input database
	# (but is not a new database)
	my $input_t  = (stat(ORDB::CPANTS->sqlite))[9];
	my $output_t = (stat(CPANTS::Weight->sqlite))[9];
	# if ( $output_t > $input_t and CPANTS::Weight::AuthorWeight->count ) {
	#	return 1;
	# }
	
	# Get the various dist scores
	my $weight     = CPANTS::Weight->all_weights;
	my $volatility = CPANTS::Weight->all_volatility;

	# Populate the AuthorWeight objects
	CPANTS::Weight->begin;
	CPANTS::Weight::AuthorWeight->truncate;
	foreach my $author (
		ORDB::CPANTS::Author->select('where pauseid is not null')
	) {
		CPANTS::Weight::AuthorWeight->create(
			id      => $author->id,
			pauseid => $author->pauseid,
		);
	}
	CPANTS::Weight->commit;

	# Populate the DistWeight objects
	CPANTS::Weight->begin;
	CPANTS::Weight::DistWeight->truncate;
	foreach my $dist (
		ORDB::CPANTS::Dist->select(
			'where author not in ( select id from author where pauseid is null )'
		)
	) {
		my $id = $dist->id;
		CPANTS::Weight::DistWeight->create(
			id         => $id,
			dist       => $dist->dist,
			author     => $dist->author,
			weight     => $weight->{$id},
			volatility => $volatility->{$id},
		);
	}
	CPANTS::Weight->commit;

	return 1;
}





#####################################################################
# Methods for all dependencies

sub all_source {
	Algorithm::Dependency::Source::DBI->new(
		dbh            => ORDB::CPANTS->dbh,
		select_ids     => "$SELECT_IDS",
		select_depends => "$SELECT_DEPENDS and ( is_prereq = 1 or is_build_prereq = 1 )",
	);
}

sub all_weights {
	Algorithm::Dependency::Weight->new(
		source => $_[0]->all_source,
	)->weight_all;
}

sub all_volatility {
	Algorithm::Dependency::Weight->new(
		source => Algorithm::Dependency::Source::Invert->new(
			$_[0]->all_source,
		),
	)->weight_all;
}

1;

=pod

=head2 dsn

  my $string = Foo::Bar->dsn;

The C<dsn> accessor returns the dbi connection string used to connect
to the SQLite database as a string.

=head2 dbh

  my $handle = Foo::Bar->dbh;

To reliably prevent potential SQLite deadlocks resulting from multiple
connections in a single process, each ORLite package will only ever
maintain a single connection to the database.

During a transaction, this will be the same (cached) database handle.

Although in most situations you should not need a direct DBI connection
handle, the C<dbh> method provides a method for getting a direct
connection in a way that is compatible with ORLite's connection
management.

Please note that these connections should be short-lived, you should
never hold onto a connection beyond the immediate scope.

The transaction system in ORLite is specifically designed so that code
using the database should never have to know whether or not it is in a
transation.

Because of this, you should B<never> call the -E<gt>disconnect method
on the database handles yourself, as the handle may be that of a
currently running transaction.

Further, you should do your own transaction management on a handle
provided by the <dbh> method.

In cases where there are extreme needs, and you B<absolutely> have to
violate these connection handling rules, you should create your own
completely manual DBI-E<gt>connect call to the database, using the connect
string provided by the C<dsn> method.

The C<dbh> method returns a L<DBI::db> object, or throws an exception on
error.

=head2 begin

  Foo::Bar->begin;

The C<begin> method indicates the start of a transaction.

In the same way that ORLite allows only a single connection, likewise
it allows only a single application-wide transaction.

No indication is given as to whether you are currently in a transaction
or not, all code should be written neutrally so that it works either way
or doesn't need to care.

Returns true or throws an exception on error.

=head2 commit

  Foo::Bar->commit;

The C<commit> method commits the current transaction. If called outside
of a current transaction, it is accepted and treated as a null operation.

Once the commit has been completed, the database connection falls back
into auto-commit state. If you wish to immediately start another
transaction, you will need to issue a separate -E<gt>begin call.

Returns true or throws an exception on error.

=head2 rollback

The C<rollback> method rolls back the current transaction. If called outside
of a current transaction, it is accepted and treated as a null operation.

Once the rollback has been completed, the database connection falls back
into auto-commit state. If you wish to immediately start another
transaction, you will need to issue a separate -E<gt>begin call.

If a transaction exists at END-time as the process exits, it will be
automatically rolled back.

Returns true or throws an exception on error.

=head2 do

  Foo::Bar->do('insert into table (foo, bar) values (?, ?)', {},
      $foo_value,
      $bar_value,
  );

The C<do> method is a direct wrapper around the equivalent L<DBI> method,
but applied to the appropriate locally-provided connection or transaction.

It takes the same parameters and has the same return values and error
behaviour.

=head2 selectall_arrayref

The C<selectall_arrayref> method is a direct wrapper around the equivalent
L<DBI> method, but applied to the appropriate locally-provided connection
or transaction.

It takes the same parameters and has the same return values and error
behaviour.

=head2 selectall_hashref

The C<selectall_hashref> method is a direct wrapper around the equivalent
L<DBI> method, but applied to the appropriate locally-provided connection
or transaction.

It takes the same parameters and has the same return values and error
behaviour.

=head2 selectcol_arrayref

The C<selectcol_arrayref> method is a direct wrapper around the equivalent
L<DBI> method, but applied to the appropriate locally-provided connection
or transaction.

It takes the same parameters and has the same return values and error
behaviour.

=head2 selectrow_array

The C<selectrow_array> method is a direct wrapper around the equivalent
L<DBI> method, but applied to the appropriate locally-provided connection
or transaction.

It takes the same parameters and has the same return values and error
behaviour.

=head2 selectrow_arrayref

The C<selectrow_arrayref> method is a direct wrapper around the equivalent
L<DBI> method, but applied to the appropriate locally-provided connection
or transaction.

It takes the same parameters and has the same return values and error
behaviour.

=head2 selectrow_hashref

The C<selectrow_hashref> method is a direct wrapper around the equivalent
L<DBI> method, but applied to the appropriate locally-provided connection
or transaction.

It takes the same parameters and has the same return values and error
behaviour.

=head2 prepare

The C<prepare> method is a direct wrapper around the equivalent
L<DBI> method, but applied to the appropriate locally-provided connection
or transaction

It takes the same parameters and has the same return values and error
behaviour.

In general though, you should try to avoid the use of your own prepared
statements if possible, although this is only a recommendation and by
no means prohibited.

=head2 pragma

  # Get the user_version for the schema
  my $version = Foo::Bar->pragma('user_version');

The C<pragma> method provides a convenient method for fetching a pragma
for a datase. See the SQLite documentation for more details.

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CPANTS-Weight>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
