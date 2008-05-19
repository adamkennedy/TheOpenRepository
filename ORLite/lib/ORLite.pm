package ORLite;

=pod

=head1 NAME

ORLite - Extremely light weight SQLite-specific ORM

=head1 SYNOPSIS

  package Foo;

  use strict;
  use ORLite 'data/sqlite.db';
  
  my @adams = Foo::Person->select('where first_name = ?', 'Adam');

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
use Carp       ();
use File::Spec ();
use File::Temp ();
use DBI        ();
BEGIN {
	# DBD::SQLite has a bug that generates a false warning,
	# so we need to temporarily disable them.
	# Remove this hack once DBD::SQLite fixes the bug.
	local $^W = 0;
	require DBD::SQLite;
}

use vars qw{$VERSION %DSN %DBH};
BEGIN {
	$VERSION = '0.02';
	%DSN     = ();
	%DBH     = ();
}





#####################################################################
# Code Generation

sub import {
	return unless $_[0] eq __PACKAGE__;
	my $class = shift;
	my $file  = File::Spec->rel2abs(shift);
	my $pkg   = caller;

	# Store the dsn
	$DSN{$pkg} = "dbi:SQLite:$file";

	# Set up the base package
	my $code = <<"END_PERL";
package $pkg;

sub dsn {
	\$ORLite::DSN{'$pkg'};
}

sub dbh {
	\$ORLite::DBH{'$pkg'} or
	DBI->connect(\$ORLite::DSN{'$pkg'}) or
	Carp::croak("connect: \$DBI::errstr");
}

sub begin {
	\$ORLite::DBH{'$pkg'} or
	\$ORLite::DBH{'$pkg'} = DBI->connect(\$ORLite::DSN{'$pkg'}) or
	Carp::croak("connect: \$DBI::errstr");
	\$ORLite::DBH{'$pkg'}->begin_work;
}

sub commit {
	\$ORLite::DBH{'$pkg'} or return 1;
	\$ORLite::DBH{'$pkg'}->commit;
	\$ORLite::DBH{'$pkg'}->disconnect;
	delete \$ORLite::DBH{'$pkg'};
	return 1;
}

sub rollback {
	\$ORLite::DBH{'$pkg'} or return 1;
	\$ORLite::DBH{'$pkg'}->rollback;
	\$ORLite::DBH{'$pkg'}->disconnect;
	delete \$ORLite::DBH{'$pkg'};
	return 1;
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

	# Get the table list
	my $dbh    = DBI->connect($DSN{$pkg});
	my $tables = $dbh->selectall_arrayref(
		'select * from sqlite_master',
		{ Slice => {} },
	);

	# Generate a package for each table
	foreach my $table ( grep { lc $_->{type} eq 'table' } @$tables ) {
		my $columns = $dbh->selectall_arrayref(
			"pragma table_info('$table->{name}')",
			 { Slice => {} },
		);
		my @names = map { $_->{name} } @$columns;

		# Enhance the table hash
		$table->{pk}    = List::Util::first { $_->{pk} } @$columns;
		$table->{pk}    = $table->{pk}->{name} if $table->{pk};
		$table->{class} = ucfirst lc $table->{name};
		$table->{class} =~ s/_([a-z])/uc($1)/ge;
		$table->{class} = "${pkg}::$table->{class}";
		my $sql = $table->{sql} = { create => $table->{sql} };
		$sql->{cols}    = join ', ', @names;
		$sql->{vals}    = join ', ', ('?') x scalar @$columns;
		$sql->{select}  = "select $table->{sql}->{cols} from $table->{name}";
		$sql->{count}   = "select count(*) from $table->{name}";
		$sql->{insert}  = join ' ',
			"insert into $table->{name}" .
			"( $table->{sql}->{cols} )"  .
			" values ( $table->{sql}->{vals} )";

		# Generate the accessors
		my $accessors = join "\n\n", map { <<"END_PERL" } @$columns;
sub $_->{name} {
	\$_[0]->{$_->{name}};
}
END_PERL

		# Generate the elements in all packages
		$code .= <<"END_PERL";
package $table->{class};

\@$table->{class}::ISA = '$class';

$accessors

sub select {
	my \$class = shift;
	my \$sql   = '$sql->{select} ';
	   \$sql  .= shift if \@_;
	my \$rows  = $pkg->selectall_arrayref( \$sql, { Slice => {} }, \@_ );
	bless( \$_, '$table->{class}' ) foreach \@\$rows;
	wantarray ? \@\$rows : \$rows;
}

sub count {
	my \$class = shift;
	my \$sql   = '$sql->{count} ';
	   \$sql  .= shift if \@_;
	$pkg->selectrow_array( \$sql, {}, \@_ );
}

END_PERL

		# Generate the elements for tables with primary keys
		if ( defined $table->{pk} ) {
			my $nattr = join "\n", map { "\t\t$_ => \$attr{$_}," } @names;
			my $iattr = join "\n", map { "\t\t\$self->{$_},"       } @names;
			$code .= <<"END_PERL";

sub new {
	my \$class = shift;
	my \%attr  = \@_;
	bless {
$nattr
	}, \$class;
}

sub create {
	shift->new(\@_)->insert;
}

sub insert {
	my \$self = shift;
	my \$dbh  = $pkg->dbh;
	\$dbh->do('$sql->{insert}', {},
$iattr
	);
	\$self->{$table->{pk}} = \$dbh->func('last_insert_rowid') unless \$self->{$table->{pk}};
	return \$self;
}

sub delete {
	my \$self = shift;
	return $pkg->do(
		'delete from $table->{name} where $table->{pk} = ?',
		{}, \$self->{$table->{pk}},
	) if ref \$self;
	Carp::croak("Must use truncate to delete all rows") unless \@_;
	return $pkg->do(
		'delete from $table->{name} ' . shift,
		{}, \@_,
	);
}

END_PERL
		}
	}
	$dbh->disconnect;

	# Compile the combined code via a temp file
	my ($fh, $filename) = File::Temp::tempfile();
	$fh->print("$code\n\n1;\n");
	close $fh;
	require $filename;
	unlink $filename;

	return 1;
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
