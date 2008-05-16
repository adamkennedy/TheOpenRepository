package ORLite;

=pod

=head1 NAME

ORLite - Extremely light weight SQLite-specific ORM

=head1 SYNOPSIS

  package Foo;

  use strict;
  use ORLite 'data/sqlite.db';
  
  my @adams = ORLite::Person->select('where first_name = ?', 'Adam');

  1;

=head1 DESCRIPTION

B<THIS CODE IS EXPERIMENTAL AND SUBJECT TO CHANGE WITHOUT NOTICE>

B<YOU HAVE BEEN WARNED!>

L<SQLite> is a light weight single file SQL database that provides an excellent platform
for embedded storage of structured data.

However, while it is superficially similar to a regular server-side SQL database, SQLite
has some significant attributes that make using it like a traditional database difficult.

For example, SQLite is extremely fast to connect to compared to server databases (1000
connections per second is not unknown) and is particularly bad at concurrency, as it can
only lock transactions at a database-wide level.

This role as a superfast internal data store can clash with the roles and designs of
traditional object-relational modules like L<Class::DBI> or L<DBIx::Class>.

What this situation would seem to need is an object-relation system that is designed
specifically for SQLite and is aligned with its idiosyncracies.

ORLite is an object-relation system specifically for SQLite that follows many of the
same principles as the ::Tiny series of modules and has a design that aligns directly
to the capabilities of SQLite.

Further documentation will be available at a later time, but the synopsis gives a
pretty good idea of how it will work.

=cut

use 5.006;
use strict;
use Carp ();
use DBI  ();
BEGIN {
	# DBD::SQLite has a bug that generates a false warning,
	# so we need to temporarily disable them.
	# Remove this hack once DBD::SQLite fixes the bug.
	local $^W = 0;
	require DBD::SQLite;
}

use vars qw{$VERSION %DBH};
BEGIN {
	$VERSION = '0.01';
	%DBH     = ();
}





#####################################################################
# Code Generation

sub import {
	return unless $_[0] eq __PACKAGE__;
	my $class = shift;
	my $file  = shift;

	# Set up the ability to connect
	my $pkg  = caller;
	my $dsn  = "dbi:SQLite:$file";
	my $code = <<"END_PERL";
package $pkg;

sub dbh {
	   \$ORLite::DBH{'$pkg'}
	or DBI->connect('$dsn')
	or Carp::croak("connect: \$DBI::errstr");
}

sub begin {
	   \$ORLite::DBH{'$pkg'}
	or \$ORLite::DBH{'$pkg'} = DBI->connect('$dsn')
	or Carp::croak("connect: \$DBI::errstr");
	\$ORLite::DBH{'$pkg'}->begin_work;
}

sub commit {
	\$ORLite::DBH{'$pkg'}
	and delete(\$ORLite::DBH{'$pkg'})->commit
	or Carp::croak("commit: \$DBI::errstr");
}

sub rollback {
	\$ORLite::DBH{'$pkg'}
	and delete(\$ORLite::DBH{'$pkg'})->rollback
	or Carp::croak("rollback: \$DBI::errstr");
}

sub do {
	shift->dbh->do(\@_);
}

sub selectall_arrayref {
	shift->dbh->selectall_arrayref(\@_);
}

sub selectall_hashref {
	shift->dbh->selectall_hashref(\@_);
}

sub selectcol_arrayref {
	shift->dbh->selectcol_arrayref(\@_);
}

sub selectrow_array {
	shift->dbh->selectrow_array(\@_);
}

sub selectrow_arrayref {
	shift->dbh->selectrow_arrayref(\@_);
}

sub selectrow_hashref {
	shift->dbh->selectrow_hashref(\@_);
}

sub prepare {
	shift->dbh->prepare(\@_);
}

END_PERL
	eval( $code );
	Carp::croak("$pkg: Codegen failed") if $@;

	# Get the table list
	my $tables = $pkg->selectall_arrayref(
		'select * from sqlite_master',
		{ Slice => {} },
	);

	# Generate a package for each table
	foreach my $table ( grep { lc $_->{type} eq 'table' } @$tables ) {
		my $columns = $pkg->selectall_arrayref(
			"pragma table_info('$table->{name}')",
			 { Slice => {} },
		);

		# Generate the elements of the package
		my $subpkg = ucfirst lc $table->{name};
		$subpkg =~ s/_([a-z])/uc($1)/ge;
		$subpkg = $pkg . '::' . $subpkg;
		my $select_sql = join ', ', map { $_->{name} } @$columns;

		# Generate the package
		my $code = <<"END_PERL";
package $subpkg;

\@${subpkg}::ISA = '$class';

sub select_sql {
	'select * from $table->{name}';
}

sub select {
	my \$rows = $pkg->selectall_arrayref(
		shift->select_sql . ' ' . shift,
		\@_,
	);
	bless( \$_, '$subpkg' ) foreach \@\$rows;
	wantarray ? \@\$rows : \$rows;
}

END_PERL
		eval($code);
		die("$pkg: Codegen failed") if $@;
	}

	1;
}

1;

=pod

=head1 TO DO

- Add the functionality for modifying databases, not just read from them

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Metrics>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2008 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

