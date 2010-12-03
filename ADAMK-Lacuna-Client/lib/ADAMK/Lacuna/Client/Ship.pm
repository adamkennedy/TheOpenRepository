package ADAMK::Lacuna::Client::Ship;

use strict;
use warnings;

use Class::XSAccessor {
	getters => [ qw(
		date_available
		date_started
		hold_size
		id
		name
		spaceport
		speed
		stealth
		task
		type
		type_human
	) ],
};

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;
	return $self;
}

sub hold {
	$_[0]->{hold_size};
}

sub available {
	not defined $_[0]->{date_available};
}





######################################################################
# High Level Methods

sub push_items {
	my $self  = shift;
	my $body  = $self->spaceport->body or die "Failed to find body";
	my $trade = $body->trade_ministry  or die "Failed to find trade ministry";
	my @rv    = $trade->push_items( shift, [ @_ ], { ship_id => $self->id } );
	$self->spaceport->flush;
	return @rv;
}

1;
