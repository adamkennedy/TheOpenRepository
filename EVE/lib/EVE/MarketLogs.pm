package EVE::MarketLogs;

# Provides an abstraction over the capture and analysis of EVE market data

use 5.008;
use strict;
use warnings;
use File::Spec       0.80 ();
use File::Remove     1.48 ();
use File::Find::Rule 0.32 ();
use Parse::CSV       1.00 ();
use DateTime::Tiny   1.00 ();
use EVE::DB               ();
use EVE::Trade            ();

# Build a regex for the list of all possible regions
my $regions = join '|', sort map {
	$_->regionName
} EVE::DB::MapRegions->select('where regionName != ?', 'Unknown');





######################################################################
# Constructor and Accessors

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Check params
	unless ( $self->dir and -d $self->dir ) {
		die "Missing or invalid market log directory";
	}

	return $self;
}

sub dir {
	$_[0]->{dir};
}





######################################################################
# Main Methods

# Find market log files
sub files {
	File::Find::Rule->relative->file->name('*.txt')->in( $_[0]->dir );
}

# Delete all existing market log files
sub flush {
	my $self = shift;

	foreach my $file ( $self->files ) {
		my $path = File::Spec->catfile( $self->dir, $file );
		File::Remove::remove($path) or die "Failed to remove '$path'";
	}

	return 1;
}

sub blank {
	my $class     = shift;
	my $region    = shift;
	my $product   = shift;
	my $market_id = join( ' ', $region, $product );
	my $timestamp = DateTime::Tiny->now->as_string;

	# Does the region name exist
	my @map_region = EVE::DB::MapRegions->select(
		'where regionName = ?', $region,
	);
	unless ( @map_region and @map_region == 1 ) {
		die "Failed to find region '$region'";
	}

	# Update the mar
	my $market = undef;
	EVE::Trade->begin;
	eval {

		# Flush old records
		EVE::Trade::Market->delete('where market_id = ?', $market_id);
		EVE::Trade::Price->delete('where market_id = ?', $market_id);

		# Create new records
		$market = EVE::Trade::Market->create(
			market_id    => $market_id,
			region_id    => $map_region[0]->regionID,
			region_name  => $map_region[0]->regionName,
			product_id   => 1,
			product_name => $product,
			timestamp    => $timestamp,
		);
	};
	if ( $@ ) {
		EVE::Trade->rollback;
		die "Failed to blank market $market_id: $@";
	}
	EVE::Trade->commit;

	return $market;
}

# Parse a single file
sub parse {
	my $self = shift;
	my $file = shift;

	# Parse information from the file name
	unless ( $file =~ /^($regions)-(.+)-(.+)$/ ) {
		die "Failed to parse file name '$file'";
	}
	my $region    = $1 or die "Failed to find region in '$file'";
	my $product   = $2 or die "Failed to find product in '$file'";
	my $timestamp = $3 or die "Failed to find timestamp in '$file'";
	$timestamp =~ s/\.txt$//;
	$timestamp =~ s/(\d\d)(\d\d)(\d\d)/$1:$2:$3/;
	$timestamp =~ s/\./-/g;
	$timestamp =~ s/ /T/;

	# Does the region name exist
	my @map_region = EVE::DB::MapRegions->select(
		'where regionName = ?', $region
	);
	unless ( @map_region and @map_region == 1 ) {
		die "Failed to find region '$region'";
	}

	# Create the parser
	my $path   = File::Spec->catfile( $self->dir, $file );
	my $parser = Parse::CSV->new(
		file   => $path,
		fields => 'auto',
	) or die "Failed to create parser for '$path'";

	my $market = undef;
	EVE::Trade->begin;
	eval {
		my $market_id = join( ' ', $region, $product );

		# Flush old records
		EVE::Trade::Market->delete('where market_id = ?', $market_id);
		EVE::Trade::Price->delete('where market_id = ?', $market_id);

		# Create new records
		$market = EVE::Trade::Market->create(
			market_id    => $market_id,
			region_id    => $map_region[0]->regionID,
			region_name  => $map_region[0]->regionName,
			product_id   => 1,
			product_name => $product,
			timestamp    => $timestamp,
		);
		while ( my $hash = $parser->fetch ) {
			$hash->{issued} =~ s/\.000$//;
			$hash->{bid} = ($hash->{bid} eq 'True') ? 1 : 0;
			EVE::Trade::Price->create(
				order_id   => $hash->{orderID},
				market_id  => $market_id,
				system_id  => $hash->{solarSystemID},
				station_id => $hash->{stationID},
				issued     => $hash->{issued},
				duration   => $hash->{duration},
				bid        => $hash->{bid},
				price      => $hash->{price},
				range      => $hash->{range},
				entered    => $hash->{volEntered},
				minimum    => $hash->{minVolume},
				remaining  => $hash->{volRemaining},
				type_id    => $hash->{typeID},
				jumps      => $hash->{jumps},
			);
		}
	};
	if ( $@ or $parser->errstr ) {
		EVE::Trade->rollback;
		die "Failed to parse '$path': " . ($@ || $parser->errstr);
	}
	EVE::Trade->commit;

	return $market;
}

sub parse_markets {
	my $self    = shift;
	my @markets = ();
	my @files   = $self->files;
	unless ( @files ) {
		sleep(1);
		@files = $self->files;
	}
	unless ( @files ) {
		sleep(1);
		@files = $self->files;
	}

	foreach my $file ( @files ) {
		push @markets, $self->parse($file);
	}

	return @markets;
}

sub parse_orders {
	my $self  = shift;
	my @files = ();
	foreach ( 1 .. 5 ) {
		@files = grep { /^My orders/ } $self->files;
		last if @files;
	}
	unless ( @files == 1 ) {
		my $found = scalar @files;
		die "Found more or less than 1 file (Found $found)";
	}

	# Parse information from the file name
	# Parse information from the file name
	my $file = $files[0];
	unless ( $file =~ /^My orders-(.+)$/ ) {
		die "Failed to parse file name '$file'";
	}
	my $timestamp = $1 or die "Failed to find timestamp in '$file'";
	$timestamp =~ s/\.txt$//;
	$timestamp =~ s/(\d\d)(\d\d)(\d\d)/$1:$2:$3/;
	$timestamp =~ s/\./-/g;
	$timestamp =~ s/ /T/;

	# Create the parser
	my $path   = File::Spec->catfile( $self->dir, $file );
	my $parser = Parse::CSV->new(
		file   => $path,
		fields => 'auto',
	) or die "Failed to create parser for '$path'";

	# Update the orders table
	my @orders = ();
	EVE::Trade->begin;
	eval {
		# Update the entire table
		EVE::Trade::MyOrder->truncate;
		while ( my $hash = $parser->fetch ) {
			$hash->{issued} =~ s/\.000$//;
			$hash->{bid} = ($hash->{bid} eq 'True') ? 1 : 0;
			$hash->{isCorp} = ($hash->{isCorp} eq 'True') ? 1 : 0;
			$hash->{contraband} = ($hash->{contraband} eq 'True') ? 1 : 0;
			push @orders, EVE::Trade::MyOrder->create(
				order_id     => $hash->{orderID},
				account_id   => $hash->{accountID},
				char_id      => $hash->{charID},
				char_name    => $hash->{charName},
				region_id    => $hash->{regionID},
				region_name  => $hash->{regionName},
				system_id    => $hash->{solarSystemID},
				system_name  => $hash->{solarSystemName},
				station_id   => $hash->{stationID},
				station_name => $hash->{stationName},
				type_id      => $hash->{typeID},
				duration     => $hash->{duration},
				bid          => $hash->{bid},
				price        => $hash->{price},
				range        => $hash->{range},
				entered      => $hash->{volEntered},
				minimum      => $hash->{minVolume},
				remaining    => $hash->{volRemaining},
				is_corp      => $hash->{isCorp},
				contraband   => $hash->{contraband},
				escrow       => $hash->{escrow},
				timestamp    => $timestamp,
			);
		}
	};
	if ( $@ or $parser->errstr ) {
		EVE::Trade->rollback;
		die "Failed to parse '$path': " . ($@ || $parser->errstr);
	}
	EVE::Trade->commit;

	return @orders;
}

1;
