package EVE::Trade::Market;

use strict;
use EVE::Trade        ();
use EVE::DB::InvTypes ();

our $VERSION = '0.01';





######################################################################
# Class Methods

use constant JITA_REGION  => 10000002;
use constant JITA_STATION => 60003760;

sub jita {
	my $class     = shift;
	my $type      = EVE::DB::InvTypes->load(shift);
	my $quantity  = shift || 1;
	my $region    = EVE::DB::MapRegions->load(JITA_REGION);
	my $market_id = join ' ', $region->regionName, $type->typeName;
	my $self      = eval {
		EVE::Trade::Market->load($market_id)
	};
	return if $@;
	return {
		region_id  => JITA_REGION,
		station_id => JITA_STATION,
		market_id  => $market_id,
		timestamp  => $self->timestamp,
		type_id    => $type->typeID,
		quantity   => $quantity,
		buy        => $self->buy( JITA_STATION, $quantity ),
		sell       => $self->sell( JITA_STATION, $quantity ),
	};
}





######################################################################
# Instance Methods

sub buy {
	my $self       = shift;
	my $station_id = shift;
	my $quantity   = shift;

	return $self->fill(
		$quantity,
		sort {
			$a->price <=> $b->price
		} $self->prices(
			station_id => $station_id,
			bid        => 0,
		)
	);
}

sub sell {
	my $self       = shift;
	my $station_id = shift;
	my $quantity   = shift;

	return $self->fill(
		$quantity,
		sort {
			$b->price <=> $a->price
		} $self->prices(
			station_id => $station_id,
			bid        => 1,
		)
	);
}

sub prices {
	my $self  = shift;
	my %where = ( @_, market_id => $self->market_id );
	my $sql   = join ' and ', map { "$_ = ?" } sort keys %where;
	EVE::Trade::Price->select(
		"where $sql",
		map { $where{$_} } sort keys %where,
	);
}

sub fill {
	my $self     = shift;
	my $quantity = shift;
	my $need     = $quantity;
	my $cost     = 0;
	while ( @_ ) {
		my $price = shift @_;
		if ( $need < $price->minimum ) {
			# We need less than they want to trade
			next;
		}
		if ( $price->remaining < $need ) {
			$cost += $price->price * $price->remaining;
			$need -= $price->remaining;
		} else {
			$cost += $price->price * $need;
			$need  = 0;
			return {
				ok     => 1,
				filled => $quantity,
				total  => $cost,
				price  => $cost / $quantity,
			};
		}
	}

	# Can't fill the order
	return {
		ok     => 0,
		filled => $quantity - $need,
		total  => $cost,
		price  => $cost / ($quantity - $need),
	};
}

1;
