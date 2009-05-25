package Perl::Metrics2;

=pod

=head1 NAME

Perl::Metrics2 - Perl metrics storage and processing engine

=head1 DESCRIPTION

B<THIS IS AN EXPERIMENTAL MODULE AND MAY CHANGE WITHOUT NOTICE>

B<Perl::Metrics2> is a 2nd-generation implementation of the Perl Code
Metrics System.

The Perl Code Metrics System is a module which provides a Perl document
metrics processing engine, and a database in which to store the
resulting metrics data.

The intent is to be able to take a large collection of Perl documents,
and relatively easily parse the files and run a series of processes on
the documents.

The resulting data can then be stored, and later used to generate useful
information about the documents.

=head2 General Structure

Perl::Metrics2 consists of two primary elements. Firstly, an
L<ORLite> database that stores the metrics informationg.

See L<Perl::Metrics2::FileMetrics> for the data class stored in the
database.

The second element is a plugin structure for creating metrics packages,
so that the metrics capture can be done independant of the underlying
mechanisms used for parsing, storage and analysis.

See L<Perl::Metrics2::Plugin> for more information.

=head2 Getting Started

C<Perl::Metrics2> comes with on default plugin,
L<Perl::Metrics2::Plugin::Core>, which provides a sampling of metrics.

To get started load the module, providing the database location as a
param (it will create it if needed). Then call the C<process_directory>
method, providing it with an absolute path to a directory of Perl code
on the local filesystem.

C<Perl::Metrics> will work on the files in the directory, and when it
finishes you will have a nice database full of metrics data about your
files.

Of course, how you actually USE that data is up to you, but you can
query L<Perl::Metrics2::FileMetric> just like any other L<ORLite>
database once you have collected it all.

=head1 METHODS

=cut

use 5.008005;
use strict;
use Carp                   ();
use DBI                    ();
use Time::HiRes            ();
use Time::Elapsed          ();
use File::Spec             ();
use File::HomeDir          ();
use File::ShareDir         ();
use File::Find::Rule       ();
use File::Find::Rule::VCS  ();
use File::Find::Rule::Perl ();
use Params::Util           ();
use PPI::Util              ();
use PPI::Document          ();
use PPI::Cache             ();
use Module::Pluggable;

our $VERSION = '0.03';

use constant ORLITE_FILE => File::Spec->catfile(
	File::HomeDir->my_data,
	($^O eq 'MSWin32' ? 'Perl' : '.perl'),
	'Perl-Metrics2',
	'Perl-Metrics2.sqlite',
);

use constant ORLITE_TIMELINE => File::Spec->catdir(
	File::ShareDir::dist_dir('Perl-Metrics2'),
	'timeline',
);

use ORLite          1.21 ();
use ORLite::Migrate 0.03 {
	file         => ORLITE_FILE,
	create       => 1,
	timeline     => ORLITE_TIMELINE,
	user_version => 2,
};





#####################################################################
# Constructor

sub new {
	my $class = shift;
	my $self  = bless { @_,
		plugins => {},
	}, $class;

	# Load the plugins
	foreach my $plugin ( $class->plugins ) {
		eval "require $plugin";
		die $@ if $@;
		$self->{plugins}->{$plugin} = $plugin->new;
		$self->{plugins}->{$plugin}->study if $self->study;
	}

	# Initialise the PPI cache if available
	if ( $self->cache ) {
		PPI::Cache->import( path => $self->cache );
	}

	return $self;
}

sub study {
	$_[0]->{study};
}

sub cache {
	$_[0]->{cache};
}

sub seen {
	my $self = shift;
	my $md5  = shift;
	foreach my $plugin ( sort keys %{$self->{plugins}} ) {
		next if $self->{plugins}->{$plugin}->{seen}->{$md5};
		return 0;
	}
	return 1;
}





#####################################################################
# Main Methods

sub process_cache {
	my $self = shift;
	unless ( $self->cache ) {
		Carp::croak("No cache provided, cannot process_cache");
	}
	unless ( $self->study ) {
		Carp::croak("Must have study true to process_cache");
	}

	# Find all the files in the cache
	$self->trace("Scanning cache directory " . $self->cache . "...");
	my @files = File::Find::Rule->name(qr/\.ppi\z/)->in($self->cache);
	$self->trace("Found " . scalar(@files) . " documents");

	# Filter and sort the documents
	$self->trace("Cleaning, filtering and sorting documents...");
	@files = map {
		# Remove the schwartian
		$_->[1]
	} sort {
		# Smallest files first (for lowest parser stress)
		$a->[2] <=> $b->[2]
	} grep {
		# Filter out things we've done already
		not $self->seen($_->[1])
	} map {
		# Set up for the Schwartzian transform
		/([a-f0-9]+).ppi\z/ ? [ $_, "$1", (stat($_))[7] ] : ()
	} @files;
	$self->trace("Filtered to " . scalar(@files) . " documents");

	# Shortcut if there's nothing to do
	unless ( @files ) {
		return 1;
	}

	# Remove indexes to speed up inserts
	$self->trace("Removing indexes for faster inserts...");
	foreach my $col ( qw{ md5 name package value version } ) {
		my $sql = "DROP INDEX IF EXISTS file_metric__$col";
		$self->trace($sql);
		Perl::Metrics2->do($sql);
	}

	my $last  = 0;
	my $count = 0;
	my $total = scalar(@files);
	my $time  = Time::HiRes::time();
	my $rate  = 0;
	my $left  = 0;
	$self->begin;
	foreach my $md5 ( @files ) {
		$self->trace(
			sprintf(
				"%s - %d of %d @ %.1f/sec (%s remaining)",
				$md5, ++$count, $total, $rate,
				Time::Elapsed::elapsed($left),
			)
		);

		# Fetch the document from the cache and process it
		my $document = PPI::Document->get_cache->get_document($md5);
		unless ( $document ) {
			warn("Failed to retrieve $md5 from the cache");
			next;
		}

		$self->process_document($document, 'safe');
		$rate = ($count - $last) / (Time::HiRes::time() - $time);
		$left = ($total - $count + 1) / $rate;
		next if $count % 100;
		$last = $count;
		$time = Time::HiRes::time();
		$self->commit_begin;
	}
	$self->commit;

	# Add the indexes back to the database
	$self->trace("Restoring indexes...");
	foreach my $col ( qw{ md5 name package value version } ) {
		my $sql = "CREATE INDEX IF NOT EXISTS file_metric__$col ON file_metric ( $col )";
		$self->trace($sql);
		Perl::Metrics2->do($sql);
	}

	return 1;
}

sub process_distribution {
	my $self = shift;

	# Get and check the directory name
	my $path = File::Spec->canonpath(shift);
	unless ( defined Params::Util::_STRING($path) ) {
		Carp::croak("Did not pass a file name to index_file");
	}
	unless ( File::Spec->file_name_is_absolute($path) ) {
		Carp::croak("Cannot index relative path '$path'. Must be absolute");
	}
	Carp::croak("Cannot index '$path'. File does not exist") unless -d $path;
	Carp::croak("Cannot index '$path'. No read permissions") unless -r _;

	# Find the documents
	my @files = File::Find::Rule->ignore_svn->no_index->perl_module->in($path);
	$self->trace("$path: Found " . scalar(@files) . " files");
	foreach my $file ( @files ) {
		$self->trace($file);
		$self->process_file($file);
	}
	return 1;
}

sub process_file {
	my $self = shift;

	# Get and check the filename
	my $path = File::Spec->canonpath(shift);
	unless ( defined Params::Util::_STRING($path) ) {
		Carp::croak("Did not pass a file name to index_file");
	}
	unless ( File::Spec->file_name_is_absolute($path) ) {
		Carp::croak("Cannot index relative path '$path'. Must be absolute");
	}
	Carp::croak("Cannot index '$path'. File does not exist") unless -f $path;
	Carp::croak("Cannot index '$path'. No read permissions") unless -r _;

	if ( $self->study ) {
		# If and only if every plugin has seen the document
		# we can shortcut and don't need to load it.
		my $md5 = PPI::Util::md5hex_file($path);
		if ( $self->seen($md5) ) {
			return 1;
		}
	}
	
	# Load the document
	my $document = PPI::Document->new( $path,
		readonly => 1,
	);
	unless ( $document ) {
		 warn("Failed to parse '$path'");
		 next;
	}

	$self->process_document($document);
}

# Forcefully process a docucment
sub process_document {
	my $self     = shift;
	my $document = shift;

	# Create the plugin objects
	foreach my $name ( sort keys %{$self->{plugins}} ) {
		$self->{plugins}->{$name}->process_document($document, @_);
	}

	return 1;
}

sub index_distribution {
	my $self = shift;
	my $dist = shift;
	my $path = shift;

	# Find the documents
	my @files = File::Find::Rule->ignore_svn
		->no_index
		->perl_file
		->relative
		->in($path);

	# Generate the md5 checksums for the files
	my %md5 = map {
		$_ => PPI::Util::md5hex_file(
			File::Spec->catfile($path, $_)
		)
	} @files;

	# Flush and push the files into the database
	Perl::Metrics2::CpanFile->delete(
		'where dist = ?', $dist,
	);
	foreach my $file ( @files ) {
		Perl::Metrics2::CpanFile->create(
			dist => $dist,
			file => $file,
			md5  => $md5{$file},
		);
	}

	return 1;
}





#####################################################################
# Support Methods

sub trace {
	print STDERR map { "# $_\n" } @_[1..$#_];
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Metrics2>

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
