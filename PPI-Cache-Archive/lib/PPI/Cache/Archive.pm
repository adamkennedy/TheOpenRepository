package PPI::Cache::Archive;

use 5.008;
use strict;
use PPI::Cache            1.203 ();
use File::Spec             0.80 ();
use File::Path             2.07 ();
use File::Remove           1.42 ();
use File::Basename            0 ();
use File::Find::Rule       0.30 ();
use File::Find::Rule::VCS  1.05 ();
use File::Find::Rule::Perl 1.06 ();

our $VERSION = '0.01';

sub create {
	my $archive  = shift;
	my $cachedir = shift;
	my $stage    = shift;
	unless ( $archive and -d File::Basename::dirname($archive) ) {
		die("Unable to create archive '$archive'");
	}
	unless ( $cachedir and -d $cachedir ) {
		die("Missing or invalid cache dir '$cachedir'");
	}
	unless ( $stage and -d $stage ) {
		die("Missing or invalid stage dir '$stage'");
	}
	if ( -d $stage ) {
		# Remove and recreate the stage directory
		trace("Clearing '$stage'");
		File::Remove::remove($stage);
		mkdir($stage);
	}

	# Create the cache object
	my $cache = PPI::Cache->new( path => $cachedir );

	# Find all the files in the cache
	trace("Scanning cache directory $cachedir...");
	my @files = File::Find::Rule->name(qr/\.ppi\z/)->relative->in($cachedir);
	@files = map {
		# Remove the schwartian
		$_->[0]
	} sort {
		# Smallest files first (for lowest parser stress)
		$a->[1] <=> $b->[1]
	} map {
		# Set up for the Schwartzian transform
		[ $_, (stat(File::Spec->catfile($cachedir, $_)))[7] ]
	} @files;
	trace("Found " . scalar(@files) . " documents");

	my $count = 0;
	my $total = scalar @files;
	foreach my $file ( @files ) {
		# Prepare paths
		next unless $file =~ /([a-z0-9]{32})\.ppi\z/;
		my $md5  = "$1";
		my $perl = $file;
		$perl =~ s/ppi\z/perl/;
		trace("$md5 - " . ++$count . " of $total");

		# Prepare the save directory
		my $save = File::Spec->catfile( $stage, $perl );
		next if -f $save;
		File::Path::make_path(
			File::Basename::dirname($save)
		);

		# Load the document
		my $document = $cache->get_document($md5);
		unless ( $document ) {
			die("Failed to load document $md5");
		}


		# Save the document
		$document->save( $save ) or die("Failed to save $md5");
	}

	return 1;
}

sub extract {
	my $archive = shift;
	my $cache   = shift;
	my $stage   = shift;

}





#####################################################################
# Support Methods

sub trace {
	print STDERR map { "# $_\n" } @_[0..$#_];
}

1;
