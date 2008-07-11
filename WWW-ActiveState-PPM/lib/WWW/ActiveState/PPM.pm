package WWW::ActiveState::PPM;

use 5.006;
use strict;
use LWP::Simple ();

my $BASEURI = "http://ppm.activestate.com/BuildStatus/";





#####################################################################
# Constructor

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;
	$self->{version} ||= '5.10';
	$self->{trace}     = !! $self->{trace};
	$self->{dists}     = {};
	return $self;
}

sub trace {
	$_[0]->{trace};
}

sub version {
	$_[0]->{version};
}

sub run {
	my $self = shift;
	foreach my $letter ( 'A' .. 'Z' ) {
		my $uri = "$BASEURI$self->{version}-$letter.html";
		print "Processing letter $letter...\n" if $self->trace;
		$self->scrape( $uri );
	}
	return 1;	
}

sub scrape {
	my $self    = shift;
	my $uri     = shift;
	my $content = LWP::Simple::get($uri);
	unless ( defined $content ) {
		die "Failed to fetch $uri";
	}

	# Get the table
	unless ( $content =~ /\<table id\=\"packages\"\>(.+?)\<\/table\>/ ) {
		die "Failed to find packages table";
	}
	my $table = $1;

	# Separate out the rows
	my @rows = $table =~ /\<tr\b[^>]*\>(.+?)\<\/tr\>/g;
	unless ( @rows ) {
		die "Failed to find rows";
	}

	# Get the platforms
	my $headers   = $rows[0];
	my @platforms = $headers =~ /\<th class\=\"platform\"\>(\w+)\<\/th\>/g;
	unless ( @platforms ) {
		die "Failed to find platforms";
	}

	# Process the rows
	foreach my $rownum ( 1 .. $#rows ) {
		my $row    = $rows[$rownum];
		my $record = {};
		unless ( $row =~ /\<td class\=\"package\"\>(.+?)\<\/td\>/;
			die "Failed to find package on row $rownum";
		}
		my $pkg = $record->{package} = $1;
		unless ( $row =~ /\<td class\=\"package\"\>(.+?)\<\/td\>/ ) {
			die "Failed to find version on row $rownum";
		}
		$record->{version} = $1;
		my @results = $row =~ /\<td class\=\"(pass|fail|core)\"\>.+?\<\/td\>/;
		unless ( @results = @platforms ) {
			die "Failed to find expected results on row $rownum";
		}
		foreach ( 0 .. $#platforms ) {
			$record->{$platforms[$_]} = $results[$_];
		}

		# Add to the collection
		$self->{dists}->{$pkg} = $record;
	}

	return 1;
}

1;
