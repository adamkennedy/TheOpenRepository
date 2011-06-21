package EVE::Plan;

# Decision support tool for calculating profitability of various actions

use strict;
use EVE::DB   ();
use EVE::Game ();

our $VERSION = '0.01';

use constant JITA => 60003760;





######################################################################
# Reactions

sub reactions {
	my $class = shift;
	my $game  = shift;

	# Capture pricing for all inputs and outputs
	my @types = EVE::DB::InvTypes->select(
		'where typeID in ( select typeID from invTypeReactions )'
		. ' and marketGroupID is not null order by typeName'
	);
	$game->market_types(@types);

	1;
}

sub manufacturing {
	my $class = shift;
	my $game  = shift;

	# Capture pricing for the main inputs
	my $inputs = EVE::DB->selectall_arrayref(<<'END_SQL');
select materialTypeID, count(*) as total
from invTypeMaterials
where materialTypeID in (
    select typeID from invTypes where marketGroupID is not null
)
group by materialTypeID
order by total desc
END_SQL
	$game->market_types(
		map { $_->[0] } grep { $_->[1] > 0 } @$inputs
	);

	1;
}

1;
