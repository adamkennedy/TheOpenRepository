package EVE::Pricing;

# An object for collecting and executing pricing instructions

use strict;
use EVE::DB;
use EVE::Trade;

# We don't list bother with completely raw materials
use constant PLANETARY => qw{
	3645 3683 2393 2396 3779 2401 2390 2397 2392 2389 2399 2395 2398 9828
	2400 2329 3828 9836 9832 44 3693 15317 3725 3689 2327 9842 2463 2317	2321 3695 9830 3697 9838 2312 3691 2319 9840 3775 2328 2358 2345 2344	2367 17392 2348 9834 2366 2361 17898 2360 2354 2352 9846 9848 2351 2349	2346 12836 17136 28974 2867 2868 2869 2870 2871 2872 2875 2876 
};

use constant INELASTIC => (
	26697, # Cloaking Device I
	11370, # Prototype Cloaking Device I
	16274, # Helium Isotopes
	17887, # Oxygen Isotopes
	17888, # Nitrogen Isotopes
	17889, # Hydrogen Isotopes
	16273, # Liquid Ozone

	# Mid-level inelastic
	31790, # Medium Core Defense Field Extender I
	31802, # Medium Core Defense Field Purger I
	31370, # Small Capacitor Control Circuit I
	25948, # Large Capacitor Control Circuit I
	31372, # Medium Capacitor Control Circuit I
);





######################################################################
# Constructor and Accessors

sub new {
	my $class = shift;
	my $self  = bless [ ], $class;
	foreach my $method ( map { "add_$_" } @_ ) {
		$self->$method();
	}
	return $self;
}

sub types {
	my $self = shift;
	my %seen = ();
	grep { not $seen{$_}++ } @$self;
}





######################################################################
# Population Methods

sub add_planetary {
	my $self = shift;
	push @$self, PLANETARY_INTERACTION;
}

sub add_inelastic {
	my $self = shift;
	push @$self, INELASTIC;
}

sub add_manufacturing {
	my $self = shift;

	# Identify manufacturing inputs
	my $inputs = EVE::DB->selectall_arrayref(<<'END_SQL');
select materialTypeID, count(*) as total
from invTypeMaterials
where materialTypeID in (
    select typeID from invTypes where marketGroupID is not null
)
group by materialTypeID
order by total desc
END_SQL

	push @$self, map { $_->[0] } grep { $_->[1] > 0 };
}

sub add_orders {
	my $self = shift;

	# Identify active orders
	my @orders = EVE::Trade::MyOrder->select;

	push @$self, map { $_->type_id } @orders;
}

sub add_assets {
	my $self = shift;

	# Fetch the list of all assets
	my @assets = EVE::Trade::Asset->select;

	# Build a type index for the base price
	my $base = EVE::DB->selectcol_hashref(<<'END_SQL');
select typeID, basePrice
from invTypes
where marketGroupID is not null
END_SQL

	# Build a type index for the market price
	my $market = EVE::Trade->selectcol_hashref(<<'END_SQL', {}, JITA );
select type_id, max(price) from price
where station_id = ?
and bid = 1
group by type_id
END_SQL

	# Establish a priority for the assets
	my %total = ();
	foreach my $asset ( @assets ) {
		my $id    = $asset->type_id;
		my $price = $market->{$id} || $base->{$id} || 0;
		$total{$id} ||= 0;
		$total{$id} += $asset->quantity * $price;
	}
	my @order = map {
		$_->[0]
	} sort {
		$a->[1] <=> $b->[1]
		or
		$b->[2] <=> $a->[2]
	} map { [
		$_,
		defined($market->{$_}) ? 1 : 0,
		$total{$_},
	] } keys %total;

	push @$self, @order;
}

1;
