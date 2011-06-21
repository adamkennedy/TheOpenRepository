package EVE::Trade::MyOrder;

use strict;
use EVE::DB            ();
use EVE::Trade         ();
use EVE::Trade::Market ();

our $VERSION = '0.01';





######################################################################
# Instance Methods

sub sold {
	$_[0]->entered - $_[0]->remaining;
}

sub type {
	EVE::DB::InvTypes->load($_[0]->type_id);
}

sub jita {
	EVE::Trade::Market->jita( $_[0]->type_id );
}

sub margin {
	my $self = shift;
	my $jita = shift || $self->jita or return;
	$jita->{sell}->{ok} or return;
	return $self->price - $jita->{sell}->{price};
}

1;
