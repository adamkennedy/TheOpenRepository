package DBIx::Publish;

=pod

=head1 NAME

DBIx::Publish - Publish data from DBI as a SQLite database

=head1 SYNOPSIS

  my $publish = DBIx::Publish->new(
      file   => 'publish.sqlite',
      source => DBI->connect($dsn, $user, $pass),
  );
  
  $publish->table( 'table1',
      'select * from foo where this < 10',
  );
  
  $publish->finish;

=head1 DESCRIPTION

B<THIS MODULE IS EXPERIMENTAL>

This is an experimental module that automates the publishing of data from
arbitrary DBI handles to a SQLite file suitable for publishing online
for others to download.

It takes a set of queries, analyses the data returned by the query,
then creates a table in the output SQLite database.

In the process, it also ensures all the optimal pragmas are set,
an index is places on every column in every table, and the database
is fully vacuumed.

As a result, you should be able to connect to any arbitrary datasource
using any arbitrary DBI driver and then map an arbitrary series of 
SQL queries like views into the published SQLite database.

=cut

use 5.006;
use strict;
use warnings;
use bytes        ();
use Carp         'croak';
use File::Remove ();
use Params::Util ();
use DBI          ();
use DBD::SQLite  ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.07';
}

use Object::Tiny 1.06 qw{
	clear
	file
	source
	dbh
	sqlite_cache
};





#####################################################################
# Constructor

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Delete the target file if we have the clear param
	if ( $self->clear and -f $self->file ) {
		File::Remove::remove($self->file);
	}

	# Connect to the SQLite database
	my $dsn = "DBI:SQLite:" . $self->file;
	$self->{dbh} = DBI->connect( $dsn, '', '', {
		PrintError => 1,
		RaiseError => 1,
	} );

	return $self;
}

# Prepare the SQLite database
sub prepare {
	my $self = shift;

	# Maximise compatibility
	$self->dbh->do('PRAGMA legacy_file_format = 1');

	# Turn on all the go-faster pragmas
	$self->dbh->do('PRAGMA synchronous  = 0');
	$self->dbh->do('PRAGMA temp_store   = 2');
	$self->dbh->do('PRAGMA journal_mode = OFF');
	$self->dbh->do('PRAGMA locking_mode = EXCLUSIVE');

	# Disable auto-vacuuming because we'll only fill this once.
	# Do a one-time vacuum so we start with a clean empty database.
	$self->dbh->do('PRAGMA auto_vacuum = 0');
	$self->dbh->do('VACUUM');

	# Set the page cache if needed
	if ( Params::Util::_POSINT($self->sqlite_cache) ) {
		my $page_size = $self->dbh->selectrow_arrayref('PRAGMA page_size')->[0];
		if ( $page_size ) {
			my $cache_size = $self->sqlite_cache * 1024 * 1024 / $page_size;
			$self->dbh->do("PRAGMA cache_size = $cache_size");
		}
	}

	return 1;
}

# Clean up the SQLite database
sub finish {
	my $self = shift;

	# Tidy up the database
	$self->dbh->do('PRAGMA synchronous  = NORMAL');
	$self->dbh->do('PRAGMA temp_store   = 0');
	$self->dbh->do('PRAGMA locking_mode = NORMAL');

	# Temporarily disabled, takes way too long for large databases
	# $self->dbh->do('VACUUM');

	return 1;
}





#####################################################################
# Methods to populate the database

sub catalog {
	my $self = shift;
	
}

sub tables {
	my $self = shift;
	while ( @_ ) {
		$self->table( shift(@_), shift(@_) );
	}
	return 1;
}

sub table {
	my $self = shift;
	
	# Do we have support table copying from this database?
	my $dbtype = $self->source->get_info( 17 ); # SQL_DBMS_NAME
	unless ( $dbtype ) {
		die("Failed to get SQL_DBMS_NAME");
	}
	if ( $dbtype eq 'SQLite' ) {
		return $self->_table_sqlite(@_);
	}

	# Hand off to the regular select method
	my $table  = shift;
	my $from   = shift || $table;
	return $self->select( $table, "select * from $from" );
}

sub _table_sqlite {
	my $self   = shift;
	my $table  = shift;
	my $from   = shift || $table;
	
	# With a direct table copy, we can interrogate types from the
	# source table directly (hopefully).
	my $info = eval {
		$self->source->column_info('', '', $from, '%')->fetchall_arrayref( {} );
	};
	unless ( $@ eq '' and $info ) {
		# Fallback to regular type detection
		return $self->select( $table, "select * from $from" );
	}

	# Generate the column metadata
	my @columns = ();
	foreach my $column ( @$info ) {
		my $name = $column->{COLUMN_NAME};
		my $type = defined($column->{COLUMN_SIZE})
			? "$column->{TYPE_NAME}($column->{COLUMN_SIZE})"
			: $column->{TYPE_NAME};
		my $null = $column->{NULLABLE} ? "NULL" : "NOT NULL";
		push @columns, "$name $type $null";
	}

	# Create the table
	my $cols = join ",\n", map { "\t$_" } @columns;
	$self->dbh->do("CREATE TABLE $table (\n$cols\n)");

	# Fill the target table
	my $place = join ", ",  map { '?' } @$info;
	my $rows  = $self->fill(
		"INSERT INTO $table VALUES ( $place )",
		"select * from $from",
	);

	return $rows;
}

sub select {
	my $self   = shift;
	my $table  = shift;
	my $sql    = shift;
	my @params = @_;

	# Make an initial scan pass over the query and do a content-based
	# classification of the data in each column.
	my %type  = ();
	my @names = ();
	SCOPE: {
		my $sth  = $self->source->prepare($sql) or croak($DBI::errstr);
		$sth->execute( @params );
		@names = @{$sth->{NAME}};
		foreach ( @names ) {
			$type{$_} = {
				NULL      => 0,
				POSINT    => 0,
				NONNEGINT => 0,
				NUMBER    => 0,
				STRING    => {},
			};
		}
		my $rows = 0;
		while ( my $row = $sth->fetchrow_hashref ) {
			$rows++;
			foreach my $key ( sort keys %$row ) {
				my $value = $row->{$key};
				my $hash  = $type{$key};
				unless ( defined $value ) {
					$hash->{NULL}++;
					next;
				}
				$hash->{STRING}->{bytes::length($value)}++;
				next unless Params::Util::_NUMBER($value);
				$hash->{NUMBER}++;
				next unless Params::Util::_POSINT($value);
				$hash->{POSINT}++;
				next unless Params::Util::_NONNEGINT($value);
				$hash->{NONNEGINT}++;
			}
		}
		$sth->finish;
		foreach my $key ( sort keys %type ) {
			my $hash    = $type{$key};
			my $notnull = $hash->{NULL} ? 'NULL' : 'NOT NULL';
			if ( $hash->{NULL} == $rows or $hash->{NONNEGINT} == $rows ) {
				$type{$key} = "INTEGER $notnull";
				next;
			}
			if ( $hash->{NUMBER} == $rows ) {
				$type{$key} = "REAL $notnull";
				next;
			}

			# Look for various string types
			my $string  = $hash->{STRING};
			my @lengths = sort { $a <=> $b } keys %$string;
			if ( scalar(@lengths) == 1) {
				# Fixed width non-numeric field
				$type{$key} = "CHAR($lengths[0]) $notnull";
				next;
			}
			if ( $lengths[-1] <= 10 ) {
				# Short string
				$type{$key} = "VARCHAR(10) $notnull";
				next;
			}
			if ( $lengths[-1] <= 32 ) {
				# Medium string
				$type{$key} = "VARCHAR(32) $notnull";
				next;
			}
			if ( $lengths[-1] <= 255 ) {
				# Short string
				$type{$key} = "VARCHAR(255) $notnull";
				next;
			}

			# For now lets assume this is a blob
			$type{$key} = "BLOB $notnull";
		}
	}

	# Create the target table
	my $columns = join ",\n", map { "\t$_ $type{$_}" } @names;
	$self->dbh->do("CREATE TABLE $table (\n$columns\n)");

	# Fill the target table
	my $place = join ", ",  map { '?' } @names;
	my $rows  = $self->fill(
		"INSERT INTO $table VALUES ( $place )",
		$sql, @params,
	);

	return $rows;
}

sub fill {
	my $self   = shift;
	my $insert = shift;
	my $rows   = 0;

	# Launch the select query
	my $from = $self->source->prepare(shift) or croak($DBI::errstr);
	$from->execute( @_ );

	# Stream the data into the target table
	my $to = $self->dbh->prepare($insert) or croak($DBI::errstr);
	$self->dbh->begin_work;
	$self->dbh->{AutoCommit} = 0;
	while ( my $row = $from->fetchrow_arrayref ) {
		$to->execute( @$row );
		next if ++$rows % 10000;
		$self->dbh->commit;
	}
	$self->dbh->commit;
	$self->dbh->{AutoCommit} = 1;
	$to->finish;

	# Done
	$from->finish;
	return $rows;
}

sub index_table {
	my $self  = shift;
	my $table = shift;
	my $info  = $self->dbh->selectall_arrayref("PRAGMA table_info($table)");
	foreach my $column ( map { $_->[1] } @$info ) {
		$self->index_column($table, $column);
	}

	1;
}

sub index_column {
	my $self    = shift;
	my ($t, $c) = _COLUMN(@_);
	my $unique  = _UNIQUE($self->dbh, $t, $c) ? 'UNIQUE' : '';
	$self->dbh->do("CREATE $unique INDEX IF NOT EXISTS idx__${t}__${c} ON ${t} ( ${c} )");
}





#####################################################################
# Support Functions

sub _UNIQUE {
	my $dbh     = shift;
	my ($t, $c) = _COLUMN(@_);
	my $count   = $dbh->selectrow_arrayref(
		"SELECT COUNT(*), COUNT(DISTINCT $c) FROM $t"
	);
	return !! ( $count->[0] eq $count->[1] );
}

sub _COLUMN {
	(@_ == 1) ? (split /\./, $_[0]) : @_;
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DBIx-Publish>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<DBI>

=head1 COPYRIGHT

Copyright 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
