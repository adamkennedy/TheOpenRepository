package Xtract;

=pod

=head1 NAME

Xtract - Take any data source and deliver it to the world

=head1 DESCRIPTION

B<THIS APPLICATION IS HIGHLY EXPERIMENTAL>

Xtract is an command line application for extracting data out of
many different types of databases (or other things that are able
to look like a database via L<DBI>).

More information to follow...

=cut

use 5.008005;
use strict;
use warnings;
use bytes                       ();
use Carp                        'croak';
use File::Which            0.05 ();
use File::Remove           1.42 ();
use Getopt::Long           2.37 ();
use Params::Util           0.35 ();
use IPC::Run3             0.042 ();
use Time::HiRes          1.9709 ();
use Time::Elapsed          0.24 ();
use DBI                    1.57 ':sql_types';
use DBD::SQLite            1.25 ();
use IO::Compress::Gzip    2.008 ();
use IO::Compress::Bzip2   2.008 ();

use Xtract::LZMA         ();
use Xtract::Scan         ();
use Xtract::Scan::SQLite ();
use Xtract::Scan::mysql  ();

use Moose 0.73;
use MooseX::Types::Common::Numeric 0.001 'PositiveInt';

has from         => ( is => 'ro', isa => 'Str' );
has user         => ( is => 'ro', isa => 'Str' );
has pass         => ( is => 'ro', isa => 'Str' );
has to           => ( is => 'ro', isa => 'Str' );
has index        => ( is => 'ro', isa => 'Bool' );
has trace        => ( is => 'ro', isa => 'Bool' );
has sqlite_cache => ( is => 'ro', isa => PositiveInt );
has argv         => ( is => 'ro', isa => 'ArrayRef[Str]' );

no Moose;





#####################################################################
# Main Function

sub main {
	# Parse the command line options
	my $FROM  = '';
	my $USER  = '';
	my $PASS  = '';
	my $TO    = '';
	my $INDEX = '';
	my $QUIET = '';
	my $CACHE = '';
	Getopt::Long::GetOptions(
		"from=s"         => \$FROM,
		"user=s"         => \$USER,
		"pass=s"         => \$PASS,
		"to=s"           => \$TO,
		"index"          => \$INDEX,
		"quiet"          => \$QUIET,
		"sqlite_cache=i" => \$CACHE,
	) or die("Failed to parse options");

	# Prepend DBI: to the --from as a convenience if needed
	if ( defined $FROM and $FROM !~ /^DBI:/ ) {
		$FROM = "DBI:$FROM";
	}

	# Create the program instance
	my $self = Xtract->new(
		from  => $FROM,
		user  => $USER,
		pass  => $PASS,
		to    => $TO,
		index => $INDEX,
		trace => ! $QUIET,
		$CACHE ? ( sqlite_cache => $CACHE ) : (),
		argv  => [ @ARGV ],
	);

	# Run the object
	$self->run;
}





#####################################################################
# Main Execution

sub run {
	my $self  = shift;
	my $start = Time::HiRes::time();

	# Clear any existing output files
	my @files = (
		$self->to,
		$self->to_gz,
		$self->to_bz2,
		$self->to_lz,
	);
	foreach my $file ( @files ) {
		if ( defined $file and -e $file ) {
			$self->say("Deleting $file");
			File::Remove::remove($file);
		}
	}

	# Check the command
	my $command = shift(@ARGV) || 'all';
	unless ( $command eq 'all' ) {
		die("Unsupported command '$command'");
	}

	# Shortcut if there's no tables
	unless ( $self->from_tables ) {
		print "No tables to export\n";
		exit(255);
	}

	# Create the target database
	$self->say("Creating SQLite database " . $self->to);
	$self->to_prepare;

	# Push all source tables into the target database
	foreach my $table ( $self->from_tables ) {
		$self->say("Publishing table $table");
		my $tstart = Time::HiRes::time();
		my $rows   = $self->add_table( $table );
		my $rate   = int($rows / (Time::HiRes::time() - $tstart));
		$self->say("Completed  table $table ($rows rows @ $rate/sec)");
	}

	# Generate any required indexes
	if ( $self->index ) {
		foreach my $table ( $self->from_tables ) {
			$self->say("Indexing table $table");
			$self->index_table( $table );
		}
	}

	# Finish up the population phase
	$self->say("Cleaning up");
	$self->to_finish;
	$self->disconnect;

	# Generate the archive forms
	if ( $self->to_gz ) {
		$self->say("Creating gzip archive");
		IO::Compress::Gzip::gzip( $self->to => $self->to_gz )
			or die 'Failed to gzip SQLite file';
	}
	if ( $self->to_bz2 ) {
		$self->say("Creating bzip2 archive");
		IO::Compress::Bzip2::bzip2( $self->to => $self->to_bz2 )
			or die 'Failed to bzip2 SQLite file';
	}
	if ( $self->to_lz ) {
		$self->say("Creating lzma archive");
		Xtract::LZMA->compress( $self->to, $self->to_lz );
	}

	# Summarise the run
	my $elapsed = int(Time::HiRes::time() - $start);
	my $human   = Time::Elapsed::elapsed($elapsed);
	$self->say( "Extraction completed in $elapsed" );
	$self->say( "Created " . $self->to    );
	$self->say( "Created " . $self->to_gz ) if $self->to_gz;
	$self->say( "Created " . $self->to_bz2) if $self->to_bz2;
	$self->say( "Created " . $self->to_lz ) if $self->to_lz;

	return 1;
}

sub add_table {
	my $self = shift;

	# Do we have support table copying from this database?
	my $dbtype = $self->from_dbh->{Driver}->{Name};
	if ( $dbtype eq 'SQLite' ) {
		return $self->_sqlite_table(@_);
	}

	# Hand off to the regular select method
	my $table  = shift;
	my $from   = shift || $table;
	return $self->add_select( $table,
		"select * from $from"
	);
}

sub _sqlite_table {
	my $self   = shift;
	my $table  = shift;
	my $from   = shift || $table;
	
	# With a direct table copy, we can interrogate types from the
	# source table directly (hopefully).
	my $info = eval {
		$self->from_dbh->column_info(
			'', '', $from, '%'
		)->fetchall_arrayref( {} );
	};
	unless ( $@ eq '' and $info ) {
		# Fallback to regular type detection
		return $self->add_select( $table, "select * from $from" );
	}

	# Generate the column metadata
	my @type = ();
	my @blob = ();
	foreach my $column ( @$info ) {
		my $name = $column->{COLUMN_NAME};
		my $type = defined($column->{COLUMN_SIZE})
			? "$column->{TYPE_NAME}($column->{COLUMN_SIZE})"
			: $column->{TYPE_NAME};
		my $null = $column->{NULLABLE} ? "NULL" : "NOT NULL";
		push @type, "$name $type $null";
		push @blob, $column->{TYPE_NAME} eq 'BLOB' ? 1 : 0;
	}

	# Create the table
	$self->to_dbh->do(
		"CREATE TABLE $table (\n"
		. join( ",\n", map { "\t$_" } @type )
		. "\n)"
	);

	# Fill the target table
	my $placeholders = join ", ",  map { '?' } @$info;
	return $self->fill(
		select => [ "SELECT * FROM $from" ],
		insert => "INSERT INTO $table VALUES ( $placeholders )",
		blobs  => scalar(grep { $_ } @blob) ? \@blob : undef,
	);
}

sub add_select {
	my $self   = shift;
	my $table  = lc(shift);
	my $select = shift;
	my @params = @_;

	# Make an initial scan pass over the query and do a content-based
	# classification of the data in each column.
	my @names = ();
	my @type  = ();
	my @blob  = [];
	SCOPE: {
		my $sth = $self->from_dbh->prepare($select);
		unless ( $sth ) {
			croak($DBI::errstr);
		}
		$sth->execute( @params );
		@names = map { lc($_) } @{$sth->{NAME}};
		foreach ( @names ) {
			push @type, {
				NULL    => 0,
				NOTNULL => 0,
				NUMBER  => 0,
				INTEGER => 0,
				INTMIN  => undef,
				INTMAX  => undef,
				TEXT    => 0,
			};
		}
		my $rows = 0;
		while ( my $row = $sth->fetchrow_arrayref ) {
			$rows++;
			foreach my $i ( 0 .. $#names ) {
				my $value = $row->[$i];
				my $hash  = $type[$i];
				if ( defined $value ) {
					$hash->{NOTNULL}++;
				} else {
					$hash->{NULL}++;
					next;
				}
				if ( Params::Util::_NUMBER($value) ) {
					$hash->{NUMBER}++;
				} elsif ( Params::Util::_NONNEGINT($value) ) {
					$hash->{INTEGER}++;
					if ( not defined $hash->{INTMIN} or $value < $hash->{INTMIN} ) {
						$hash->{INTMIN} = $value;
					}
					if ( not defined $hash->{INTMAX} or $value > $hash->{INTMAX} ) {
						$hash->{INTMAX} = $value;
					}					
				} elsif ( length $value <= 255 ) {
					$hash->{TEXT}++;
				}
			}
		}
		$sth->finish;
		my $col = 0;
		foreach my $i ( 0 .. $#names ) {
			# Initially, assume this isn't a blob
			push @blob, 0;
			my $hash    = $type[$i];
			my $notnull = $hash->{NULL} ? 'NULL' : 'NOT NULL';
			if ( $hash->{NOTNULL} == 0 ) {
				# The column is completely null, no affinity
				$type[$i] = "$names[$i] NONE NULL";
			} elsif ( $hash->{INTEGER} == $hash->{NOTNULL} ) {
				$type[$i] = "$names[$i] INTEGER $notnull";
			} elsif ( $hash->{NUMBER} == $hash->{NOTNULL} ) {
				# This isn't entirely accurate but should be close enough
				$type[$i] = "$names[$i] REAL $notnull";
			} elsif ( $hash->{TEXT} == $hash->{NOTNULL} ) {
				$type[$i] = "$names[$i] TEXT $notnull";
			} else {
				# For now lets assume this is a blob
				$type[$i] = "$names[$i] BLOB $notnull";

				# This is a blob after all
				$blob[-1] = 1;
			}
		}
	}

	# Create the target table
	$self->to_dbh->do(
		"CREATE TABLE $table (\n"
		. join(",\n", map { "\t$_" } @type) 
		. "\n)"
	);

	# Fill the target table
	my $placeholders = join ", ",  map { '?' } @names;
	return $self->fill(
		select => [ $select, @params ],
		insert => "INSERT INTO $table VALUES ( $placeholders )",
		blobs  => scalar(grep { $_ } @blob) ? \@blob : undef,
	);
}

sub fill {
	my $self   = shift;
	my %params = @_;
	my $select = $params{select};
	my $insert = $params{insert};
	my $blobs  = $params{blobs};

	# Launch the select query
	my $from = $self->from_dbh->prepare(shift(@$select));
	unless ( $from ) {
		croak($DBI::errstr);
	}
	$from->execute(@$select);

	# Stream the data into the target table
	my $dbh = $self->to_dbh;
	$dbh->begin_work;
	$dbh->{AutoCommit} = 0;
	my $rows = 0;
	my $to   = $dbh->prepare($insert) or croak($DBI::errstr);
	while ( my $row = $from->fetchrow_arrayref ) {
		if ( $blobs ) {
			# When inserting blobs, we need to use the bind_param method
			foreach ( 0 .. $#$row ) {
				if ( $blobs->[$_] ) {
					$to->bind_param( $_ + 1, $row->[$_], SQL_BLOB );
				} else {
					$to->bind_param( $_ + 1, $row->[$_] );
				}
			}
			$to->execute;
		} else {
			$to->execute( @$row );
		}
		next if ++$rows % 10000;
		$dbh->commit;
	}
	$dbh->commit;
	$dbh->{AutoCommit} = 1;

	# Clean up
	$to->finish;
	$from->finish;

	return $rows;
}





#####################################################################
# Source Methods

sub from_dbh {
	my $self = shift;
	unless ( $self->{from_dbh} ) {
		$self->say("Connecting to " . $self->from);
		$self->{from_dbh} = DBI->connect(
			$self->from,
			$self->user,
			$self->pass,
			{
				PrintError => 1,
				RaiseError => 1,
			}
		);
		unless ( $self->{from_dbh} ) {
			die("Failed to connect to " . $self->from);
		}
	}
	return $self->{from_dbh};
}

sub from_scan {
	my $self = shift;
	unless ( $self->{from_scan} ) {
		$self->{from_scan} = Xtract::Scan->create($self->from_dbh);
	}
	return $self->{from_scan};
}

sub from_tables {
	my $self = shift;
	unless ( $self->{from_tables} ) {
		$self->{from_tables} = [ $self->from_scan->tables ];
	}
	return @{$self->{from_tables}};
}





#####################################################################
# Destination Methods

sub to_gz {
	$_[0]->to . '.gz';
}

sub to_bz2 {
	$_[0]->to . '.bz2';
}

sub to_lz {
	if ( Xtract::LZMA->available ) {
		return $_[0]->to . '.lz';
	} else {
		return;
	}
}

sub to_dsn {
	"DBI:SQLite:" . $_[0]->to
}

sub to_dbh {
	my $self = shift;
	unless ( $self->{to_dbh} ) {
		$self->{to_dbh} = DBI->connect( $self->to_dsn, '', '', {
			PrintError => 1,
			RaiseError => 1,
		} );
		unless ( $self->{to_dbh} ) {
			die("Failed to connect to " . $self->to_dsn);
		}
	}
	return $self->{to_dbh};
}

# Prepare the target database
sub to_prepare {
	my $self = shift;
	my $dbh  = $self->to_dbh;

	# Maximise compatibility
	$dbh->do('PRAGMA legacy_file_format = 1');

	# Turn on all the go-faster pragmas
	$dbh->do('PRAGMA synchronous  = 0');
	$dbh->do('PRAGMA temp_store   = 2');
	$dbh->do('PRAGMA journal_mode = OFF');
	$dbh->do('PRAGMA locking_mode = EXCLUSIVE');

	# Disable auto-vacuuming because we'll only fill this once.
	# Do a one-time vacuum so we start with a clean empty database.
	$dbh->do('PRAGMA auto_vacuum = 0');
	$dbh->do('VACUUM');

	# Set the page cache if needed
	if ( $self->sqlite_cache ) {
		my $page_size = $dbh->selectrow_arrayref('PRAGMA page_size')->[0];
		if ( $page_size ) {
			my $cache_size = $self->sqlite_cache * 1024 * 1024 / $page_size;
			$dbh->do("PRAGMA cache_size = $cache_size");
		}
	}

	return 1;
}

# Finalise the target database
sub to_finish {
	my $self = shift;
	my $dbh  = $self->to_dbh;

	# Tidy up the database
	$dbh->do('PRAGMA synchronous  = NORMAL');
	$dbh->do('PRAGMA temp_store   = 0');
	$dbh->do('PRAGMA locking_mode = NORMAL');

	return 1;
}





#####################################################################
# Support Methods

sub index_table {
	my $self  = shift;
	my $table = shift;
	my $info  = $self->to_dbh->selectall_arrayref("PRAGMA table_info($table)");
	foreach my $column ( map { $_->[1] } @$info ) {
		$self->index_column($table, $column);
	}
	return 1;
}

sub index_column {
	my $self    = shift;
	my ($t, $c) = _COLUMN(@_);
	my $unique  = _UNIQUE($self->to_dbh, $t, $c) ? 'UNIQUE' : '';
	$self->to_dbh->do("CREATE $unique INDEX IF NOT EXISTS idx__${t}__${c} ON ${t} ( ${c} )");
	return 1;
}

sub disconnect {
	my $self = shift;
	if ( $self->{from_scan} ) {
		delete($self->{from_scan});
	}
	if ( $self->{from_dbh} ) {
		delete($self->{from_dbh})->disconnect;
	}
	if ( $self->{to_dbh} ) {
		delete($self->{to_dbh})->disconnect;
	}
	return 1;
}

sub say {
	if ( Params::Util::_CODE($_[0]->trace) ) {
		$_[0]->say( @_[1..$#_] );
	} elsif ( $_[0]->trace ) {
		my $t = scalar localtime time;
		print map { "[$t] $_\n" } @_[1..$#_];
	}
}

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

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Xtract>

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
