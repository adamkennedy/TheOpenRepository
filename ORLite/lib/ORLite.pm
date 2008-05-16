package ORLite;

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
	bless( \$_, \$subpkg ) foreach \@\$rows;
	wantarray ? \@\$rows : \$rows;
}

END_PERL
		eval($code);
		die("$pkg: Codegen failed") if $@;
	}

	1;
}

1;
