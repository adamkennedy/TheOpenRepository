package EVE;

use 5.008;
use strict;
use warnings;
use EVE::Config     ();
use EVE::Trade      ();
use EVE::API        ();
use EVE::Game       ();
use EVE::MarketLogs ();

our $VERSION = '0.01';





######################################################################
# Product Catalogs

use constant MINERALS => qw{
	Isogen
	Megacyte
	Mexallon
	Morphite
	Nocxium
	Pyerite
	Tritanium
	Zydrine
};

use constant ICE_PRODUCTS => (
	'Heavy Water',
	'Helium Isotopes',
	'Hydrogen Isotopes',
	'Liquid Ozone',
	'Nitrogen Isotopes',
	'Oxygen Isotopes',
	'Strontium Clathrates',
);

use constant MOON_RAW => (
	'Atmospheric Gases',
	'Evaporite Deposits',
	qw{
		Cadmium
		Caesium
		Chromium
		Cobalt
		Dysprosium
		Hafnium
		Hydrocarbons
		Mercury
		Neodymium
		Platinum
		Promethium
		Scandium
		Silicates
		Technetium
		Thulium
		Titanium
		Tungsten
		Vanadium
	}
);

use constant MARKET_HUBS => qw{
	Jita
	Amarr
	Zinkon
	Rens
	Dodixie
	Hek
};

1;
