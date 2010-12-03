package ADAMK::Lacuna::Client::Buildings::TradeMinistry;

use 5.0080000;
use strict;
use warnings;
use ADAMK::Lacuna::Client;
use ADAMK::Lacuna::Client::Buildings;

our @ISA = qw(ADAMK::Lacuna::Client::Buildings);

our %TYPE = (
	algae        => 'food',
	anthracite   => 'ore',
	apple        => 'food',
	bauxite      => 'ore',
	beryl        => 'ore',
	chalcopyrite => 'ore',
	chromite     => 'ore',
	cheese       => 'food',
	corn         => 'food',
	energy       => 'energy',
	flourite     => 'ore',
	fungus       => 'food',
	galena       => 'ore',
	goethite     => 'ore',
	gold         => 'ore',
	gypsum       => 'ore',
	halite       => 'ore',
	kerogen      => 'ore',
	magnetite    => 'ore',
	methane      => 'ore',
	milk         => 'food',
	monazite     => 'ore',
	pie          => 'food',
	potato       => 'food',
	rutile       => 'ore',
	sulfur       => 'ore',
	trona        => 'ore',
	uraninite    => 'ore',
	shake        => 'food',
	waste        => 'waste',
	water        => 'water',
	wheat        => 'food',
	zircon       => 'ore',
);

sub api_methods {
	return {
		add_trade             => { default_args => [qw(session_id building_id)] },
		get_ships             => { default_args => [qw(session_id building_id)] },
		get_prisoners         => { default_args => [qw(session_id building_id)] },
		get_plans             => { default_args => [qw(session_id building_id)] },
		get_glyphs            => { default_args => [qw(session_id building_id)] },
		withdraw_trade        => { default_args => [qw(session_id building_id)] },
		accept_trade          => { default_args => [qw(session_id building_id)] },
		view_available_trades => { default_args => [qw(session_id building_id)] },
		view_my_trades        => { default_args => [qw(session_id building_id)] },
		get_stored_resources  => { default_args => [qw(session_id building_id)] },
		push_items            => { default_args => [qw(session_id building_id)] },
		get_trade_ships       => { default_args => [qw(session_id building_id)] },
	};
}

__PACKAGE__->init;

sub flush {
	return 1;
}

sub resources {
	my $self     = shift;
	my $response = $self->get_stored_resources;
	$self->set_status( $response->{status} );
	return $response->{resources};
}

sub resource_breakdown {
	my $self      = shift;
	my $type      = shift;
	my $quantity  = shift;
	my $resources = $self->resources;

	# Send the most abundant things first
	my @stuff = sort {
		$resources->{$b} <=> $resources->{$a}
	} grep {
		$TYPE{$_}
		and
		$TYPE{$_} eq $type
		and
		$resources->{$_}
	} keys %$resources;

	# Build the items
	my @items = ();
	while ( $quantity and @stuff ) {
		my $type = shift @stuff;
		if ( $resources->{$type} >= $quantity ) {
			push @items, {
				type     => $type,
				quantity => $quantity,
			};
			return @items;
		} else {
			push @items, {
				type     => $type,
				quantity => $resources->{$type},
			};
			$quantity -= $resources->{$type};
		}
	}

	return @items;
}

1;

__END__

=head1 NAME

ADAMK::Lacuna::Client::Buildings::TradeMinistry - The Trade Ministry building

=head1 SYNOPSIS

	use ADAMK::Lacuna::Client;

=head1 DESCRIPTION

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
