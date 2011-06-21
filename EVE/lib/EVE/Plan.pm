package EVE::Plan;

# Decision support tool for calculating profitability of various actions

use strict;
use List::MoreUtils 0.26 ();
use Text::Table    1.114 ();
use Number::Format  1.73 ();
use EVE::DB   ();
use EVE::Game ();

our $VERSION = '0.01';

use constant JITA => 60003760;

my $isk = Number::Format->new;





######################################################################
# Reports

sub sell_margins {
	my $class  = shift;
	my @orders = EVE::Trade::MyOrder->select('where bid = ?', 0);
	my @rows   = ();

	foreach my $order ( @orders ) {
		my $jita   = $order->jita;
		my $sold   = $order->sold;
		my $margin = $order->margin($jita);
		my $profit = $sold * $margin;
		push @rows, [
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
			"Product",
			{ align => 'right', align_title => 'right', title => "My Sell"   },
			{ align => 'right', align_title => 'right', title => "Jita Sell" },
			{ align => 'right', align_title => 'right', title => "Margin"    },
			{ align => 'right', align_title => 'right', title => "Sold"      },
			{ align => 'right', align_title => 'right', title => "Profit"    },
		],
		map { [
			$_->[0],
			isk($_->[1]),
			isk($_->[2]),
			isk($_->[3]),
			num($_->[4]),
			isk($_->[5]),
		] } sort {
			$a->[0] cmp $b->[0]
		} @rows,
	);
}




######################################################################
# Market Scanning

sub reactions {
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

	1;
}

sub manufacturing {
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

	1;
}

sub my_orders {
	my $class = shift;
	my $game  = shift;

	# Identify the 
	my @orders = $game->market_orders;
	$game->market_start;
	$game->market_types(
		List::MoreUtils::distinct map { $_->type_id } @orders
	);
}





######################################################################
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

sub num {
	$isk->format_number( $_[0] );
}

sub isk {
	$isk->format_number( sprintf("%.2f", $_[0]), 2, 2 );
}

1;
