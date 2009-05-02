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
use File::Which            0.05 ();
use File::Remove           1.42 ();
use Getopt::Long           2.37 ();
use Params::Util           0.35 ();
use IPC::Run3             0.042 ();
use Time::HiRes          1.9709 ();
use Time::Elapsed          0.24 ();
use DBI                    1.57 ();
use DBD::SQLite            1.25 ();
use IO::Compress::Gzip    2.008 ();
use IO::Compress::Bzip2   2.008 ();
use DBIx::Publish               ();

our $VERSION = '0.08';

use constant MSWin32 => !! ( $^O eq 'MSWin32' );

# Do we support lzma compression?
my $CAN_LZMA = 0;
if ( MSWin32 ) {
	require Alien::Win32::LZMA;
	$CAN_LZMA = 1;
} elsif ( File::Which::which('lzma') ) {
	$CAN_LZMA = 1;
}

use Moose 0.76;
use MooseX::Types::Common::Numeric 0.001 'PositiveInt';

has from         => ( is => 'ro', isa => 'Str' );
has user         => ( is => 'ro', isa => 'Str' );
has pass         => ( is => 'ro', isa => 'Str' );
has to           => ( is => 'ro', isa => 'Str' );
has index        => ( is => 'ro', isa => 'Int' );
has trace        => ( is => 'ro', isa => 'Int' );
has sqlite_cache => ( is => 'ro', isa => PositiveInt );
has argv         => ( is => 'ro', isa => 'ArrayRef[Str]' );

no Moose;





#####################################################################
# Constructor and Main Function

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
		from         => $FROM,
		user         => $USER,
		pass         => $PASS,
		to           => $TO,
		index        => $INDEX ? 1 : 0,
		trace        => $QUIET ? 0 : 1,
		$CACHE ? ( sqlite_cache => $CACHE ) : (),
#		sqlite_cache => $CACHE,
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

sub to_lz {
	if ( $CAN_LZMA ) {
		return $_[0]->to . '.lz';
	} else {
		return;
	}
}





#####################################################################
# Main Methods

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

	# Connect to the data source
	$self->say("Connecting to data source " . $self->from);
	my $source = DBI->connect( $self->from, $self->user, $self->pass, {
		PrintError => 1,
		RaiseError => 1,
	} ) or die("Failed to connect to " . $self->from);

	# Create the publish object
	$self->say("Creating SQLite database " . $self->to);
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
	$self->say("Configuring SQLite database");
	$publish->prepare;
	my @tables = grep { s/\"//g; $_ !~ /^sqlite_/ } $publish->source->tables;
	foreach my $table ( @tables ) {
		$self->say("Publishing table $table");
		my $tstart = Time::HiRes::time();
		my $rows   = $publish->table( $table );
		my $rate   = int($rows / (Time::HiRes::time() - $tstart));
		$self->say("Completed  table $table ($rows rows @ $rate/sec)");
	}
	if ( $self->index ) {
		foreach my $table ( @tables ) {
			$self->say("Indexing table $table");
			$publish->index_table( $table );
		}
	}
	$self->say("Cleaning SQLite database");
	$publish->finish;

	# Disconnect from the target database
	$publish->dbh->disconnect;

	# Compress the file
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
		if ( MSWin32 ) {
			Alien::Win32::LZMA::lzma_compress(
				$self->to => $self->to_lz,
			) or die 'Failed to lzma SQLite file';
		} else {
			my $lzma   = File::Which::which('lzma');
			my $stdout = '';
			my $stderr = '';
			IPC::Run3::run3(
				[ $lzma, 'e', $self->to, $self->to_lz ],
				\undef, \$stdout, \$stderr,
			) or die 'Failed to lzma SQLite file';
		}
	}

	# Clean up
	$source->disconnect;
	$self->say(
		"Extraction completed in " .
		Time::Elapsed::elapsed(int(Time::HiRes::time() - $start)) .
		" seconds"
	);

	# Summarise the run
	$self->say("Created " . $self->to);
	if ( $self->to_gz ) {
		$self->say("Created " . $self->to_gz);
	}
	if ( $self->to_bz2 ) {
		$self->say("Created " . $self->to_bz2);
	}
	if ( $self->to_lz ) {
		$self->say("Created " . $self->to_lz);
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
