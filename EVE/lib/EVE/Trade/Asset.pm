package EVE::Trade::Asset;

use strict;
use EVE::DB            ();
use EVE::Trade         ();
use EVE::Trade::Market ();

our $VERSION = '0.01';





######################################################################
# Instance Methods

sub type {
	EVE::DB::InvTypes->load($_[0]->type_id);
}

sub jita {
	EVE::Trade::Market->jita( shift->type_id, @_ );
}

1;
