package EVE::Plan;

# Decision support tool for calculating profitability of various actions

use strict;
use Smart::Comments 1.000;
use List::MoreUtils  0.26 ();
use Text::Table     1.114 ();
use Number::Format   1.73 ();
use EVE::DB               ();
use EVE::Game             ();

our $VERSION = '0.01';

use constant JITA      => 60003760;
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

my $isk = Number::Format->new;





# #####################################################################
# Reports

sub report_sell_orders {
	my $class  = shift;
	my @orders = EVE::Trade::MyOrder->select('where bid = ?', 0);
	my @rows   = ();

	foreach my $order ( @orders ) {   ### Working===[%]     done
		my $jita   = $order->jita;
		my $sold   = $order->sold;
		my $margin = $order->margin($jita);
		my $profit = $sold * $margin;
		push @rows, [
			$order->system_name,
			$order->type->typeName,
			$order->price,
			$jita->{sell}->{price},
			$margin,
			$sold,
			$profit,
		];
	}

	# Sort, format, and display
	print table(
		[
			"System",
			"Product",
			{ align => 'right', align_title => 'right', title => "My Sell"   },
			{ align => 'right', align_title => 'right', title => "Jita Sell" },
			{ align => 'right', align_title => 'right', title => "Margin"    },
			{ align => 'right', align_title => 'right', title => "Sold"      },
			{ align => 'right', align_title => 'right', title => "Profit"    },
		],
		map { [
			$_->[0],
			$_->[1],
			isk($_->[2]),
			isk($_->[3]),
			isk($_->[4]),
			number($_->[5]),
			isk($_->[6]),
		] } sort {
			$a->[0] cmp $b->[0]
		} @rows,
	);
}

sub report_assets {
	my $class  = shift;
	my @assets = EVE::Trade::Asset->select;
	my @rows   = ();

	foreach my $asset ( @assets ) {   ### Working===[%]     done
		my $type      = $asset->type;
		my $name      = $type->typeName;
		my $quantity  = $asset->quantity;
		my $each      = $asset->jita                   or next;
		my $all       = $asset->jita($quantity) or next;
		my $buy       = $each->{buy}->{ok}  ? $each->{buy}->{price}  : '~';
		my $sell      = $each->{sell}->{ok} ? $each->{sell}->{price} : '~';
		my $cash      = ($name =~ /\bI\b/) ? $buy * $quantity : $all->{buy}->{total};
		my $liquidity = ($each->{buy}->{price} * $quantity) / $cash;
		push @rows, [
			$asset->location_id,
			$name,
			$quantity,
			$sell,
			$buy,
			$cash,
			$liquidity,
		];
	}

	# Sort, format and display
	print table(
		[
			"Location",
			"Product",
			{ align => 'right', align_title => 'right', title => "Quantity"  },
			{ align => 'right', align_title => 'right', title => "Best Sell" },
			{ align => 'right', align_title => 'right', title => "Best Buy"  },
			{ align => 'right', align_title => 'right', title => "Jita Sale" },
			{ align => 'right', align_title => 'right', title => "Liquidity" },
		],
		map { [
			$_->[0],
			$_->[1],
			number($_->[2]),
			isk($_->[3]),
			isk($_->[4]),
			isk($_->[5]),
			percent($_->[6]),
		] } sort {
			$b->[5] <=> $a->[5]
		} @rows,
	);
}





# #####################################################################
# Market Scanning

sub scan_inelastic {
	my $class = shift;
	my $game  = shift;

	# Capture pricing from the pre-built list
	$game->market_start;
	$game->market_types( INELASTIC );
}

sub scan_reactions {
	my $class = shift;
	my $game  = shift;

	# Identify inputs used in reactions
	my @types = EVE::DB::InvTypes->select(
		'where typeID in ( select typeID from invTypeReactions )'
		. ' and marketGroupID is not null order by typeName'
	);

	# Capture pricing for them
	$game->market_start;
	$game->market_types(@types);
}

sub scan_manufacturing {
	my $class = shift;
	my $game  = shift;

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

	# Capture pricing for them
	$game->market_start;
	$game->market_types(
		map { $_->[0] } grep { $_->[1] > 0 } @$inputs
	);
}

sub scan_orders {
	my $class = shift;
	my $game  = shift;

	# Find all the orders
	my @orders = $game->market_orders;
	$game->market_start;
	$game->market_types(
		List::MoreUtils::distinct map { $_->type_id } @orders
	);
}

sub scan_assets {
	my $class = shift;
	my $game  = shift;

	# Find all the asset types
	my @assets = $game->asset_list;

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
		$b->[1] <=> $a->[1]
		or
		$b->[2] <=> $a->[2]
	} map { [
		$_,
		defined($market->{$_}) ? 1 : 0,
		$total{$_},
	] } keys %total;

	# Capture market pricing in quantity order
	$game->market_start;
	$game->market_types(@order);
}





# #####################################################################
# Support Methods

sub table {
	# Populate the table
	my $title = shift;
	my $table = Text::Table->new(
		\'| ', 
		ljoin( \' | ', map {
			ref($_) ? $_ : {
				align             => 'left',
				align_title       => 'left',
				align_title_lines => 'left',
				title             => $_,
			}
		} @$title ),
		\' |',
	);
	$table->load( @_ );

	# Generate the string form
	return join( '', "\n",
		$table->rule('-'),
		$table->title,
		$table->rule('-'),
		$table->body,
		$table->rule('-'),
	) . "\n";
}

sub ljoin {
	my $j = shift;
	if ( @_ > 1 ) {
		return ( shift, map { $j, $_ } @_ );
	} elsif ( @_ ) {
		return ( shift );
	} else {
		return ( );
	}
}

sub number {
	$isk->format_number( $_[0] );
}

sub isk {
	$isk->format_number( sprintf("%.2f", $_[0]), 2, 2 );
}

sub percent {
	int($_[0] * 100) . '%'
}

1;
