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
use Getopt::Long         2.37 ();
use File::Remove         1.42 ();
use Params::Util         0.35 ();
use Time::HiRes        1.9709 ();
use Time::Elapsed        0.24 ();
use DBI                  1.57 ();
use DBD::SQLite          1.25 ();
use IO::Compress::Gzip  2.008 ();
use IO::Compress::Bzip2 2.008 ();
use DBIx::Publish             ();

our $VERSION = '0.06';

use Object::Tiny 1.06 qw{
	from
	user
	pass
	to
	index
	sqlite_cache
	argv
};

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

	# Create the program instance
	my $self = Xtract->new(
		from         => $FROM,
		user         => $USER,
		pass         => $PASS,
		to           => $TO,
		index        => $INDEX,
		trace        => $QUIET ? 0 : 1,
		sqlite_cache => $CACHE,
		argv         => [ @ARGV ],
	);

	# Run the object
	$self->run;
}

sub to_gz {
	$_[0]->to . '.gz';
}

sub to_bz2 {
	$_[0]->to . '.bz2';
}





#####################################################################
# Main Methods

sub run {
	my $self  = shift;
	my $start = Time::HiRes::time();

	# Clear any existing output files
	foreach my $file ( $self->to, $self->to_gz, $self->to_bz2 ) {
		if ( defined $file and -e $file ) {
			$self->trace("Deleting previous $file");
			File::Remove::remove($file);
		}
	}

	# Connect to the data source
	$self->trace("Connecting to data source " . $self->from);
	my $source = DBI->connect( $self->from, $self->user, $self->pass, {
		PrintError => 1,
		RaiseError => 1,
	} ) or die("Failed to connect to " . $self->from);

	# Create the publish object
	$self->trace("Creating SQLite database " . $self->to);
	my $publish = DBIx::Publish->new(
		source       => $source,
		file         => $self->to,
		sqlite_cache => $self->sqlite_cache,
	) or die("Failed to create DBIx::Publish");

	# Check the command
	my $command = shift(@ARGV) || 'all';
	unless ( $command eq 'all' ) {
		die("Unsupported command '$command'");
	}

	# Get the list of tables
	$self->trace("Configuring SQLite database");
	$publish->prepare;
	my @tables = grep { s/\"//g; $_ !~ /^sqlite_/ } $publish->source->tables;
	foreach my $table ( @tables ) {
		$self->trace("Publishing table $table");
		my $tstart = Time::HiRes::time();
		my $rows   = $publish->table( $table );
		my $rate   = int($rows / (Time::HiRes::time() - $tstart));
		$self->trace("Completed  table $table ($rows rows @ $rate/sec)");
	}
	if ( $self->index ) {
		foreach my $table ( @tables ) {
			$self->trace("Indexing table $table");
			$publish->index_table( $table );
		}
	}
	$self->trace("Cleaning SQLite database");
	$publish->finish;

	# Compress the file
	if ( $self->to_gz ) {
		$self->trace("Creating gzip archive");
		IO::Compress::Gzip::gzip( $self->to => $self->to_gz )
			or die 'Failed to gzip SQLite file';
	}
	if ( $self->to_bz2 ) {
		$self->trace("Creating bzip2 archive");
		IO::Compress::Bzip2::bzip2( $self->to => $self->to_bz2 )
			or die 'Failed to bzip2 SQLite file';
	}

	# Clean up
	$source->disconnect;
	$self->trace(
		"Extraction completed in " .
		Time::Elapsed::elapsed(int(Time::HiRes::time() - $start)) .
		" seconds"
	);

	# Summarise the run
	$self->trace("Created " . $self->to);
	if ( $self->to_gz ) {
		$self->trace("Created " . $self->to_gz);
	}
	if ( $self->to_bz2 ) {
		$self->trace("Created " . $self->to_bz2);
	}

	return 1;
}

sub trace {
	if ( Params::Util::_CODE($_[0]->{trace}) ) {
		$_[0]->trace( @_[1..$#_] );
	} elsif ( $_[0]->{trace} ) {
		my $t = scalar localtime time;
		print map { "[$t] $_\n" } @_[1..$#_];
	}
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

L<DBI>, L<DBIx::Publish>

=head1 COPYRIGHT

Copyright 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
