package EVE::DB;

use 5.008;
use strict;
use warnings;
use ORLite         1.50 ();
use ORLite::Mirror 1.21 {
	url           => 'http://eve.no-ip.de/inc15/inc15-sqlite3-v1.db.bz2',
	maxage        => 999999999999,
	show_progress => 1,
	shim          => 1,
	tables        => [ qw{
		invMarketGroups
		invMetaTypes
		invTypes
		invTypeMaterials
		invTypeReactions
		mapRegions
		mapSolarSystems
		mapSolarSystemJumps
		staStations
		staStationTypes
	} ],
};

use EVE::DB::InvTypes   ();
use EVE::DB::MapRegions ();

our $VERSION = '0.01';

sub selectcol_hashref {
	my $class = shift;
	my $sql   = shift;
	my $attr  = shift || {};
	$attr->{Columns} ||= [ 1, 2 ];
	my $array = $class->selectcol_arrayref( $sql, $attr, @_ );
	my %hash  = @$array;
	return \%hash;
}

1;
