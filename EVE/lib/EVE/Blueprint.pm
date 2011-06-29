package EVE::Blueprint;

# Blueprint calculator

use strict;
use Params::Util ();
use EVE::Market  ();

our $VERSION = '0.01';

use Object::Tiny qw{
	output_type_id
	output_quantity
	skill_production_efficiency
	blueprint_mineral_efficiency
	blueprint_production_efficiency
	material_base
	material_cost
};





######################################################################
# Constructor and Accessors

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Apply defaults and check params
	unless ( defined $self->output_type_id ) {
		die "Missing or invalid output_type_id param";
	}
	unless ( defined $self->output_quantity ) {
		$self->{output_quantity} = 1;
	}
	unless ( defined $self->skill_production_efficiency ) {
		$self->{skill_production_efficiency} = 5;
	}
	unless ( defined $self->blueprint_mineral_efficiency ) {
		$self->{blueprint_mineral_efficiency} = 0;
	}
	unless ( defined $self->blueprint_production_efficiency ) {
		$self->{blueprint_production_efficiency} = 0;
	}

	# Do we have a set of perfect inputs
	unless ( Params::Util::_HASH($self->material_base) ) {
		die "Missing or invalid material_base param";
	}

	# Derive the actual material consumption
	$self->{material_cost} = {};
	foreach my $type_id ( $self->material_type_ids ) {
		if ( $self->blueprint_mineral_efficiency >= 0 ) {
			# cost = base * (1 + 0.1 / (ME + 1)) * (1.25 - 0.05 * ProdEff)
			$self->{material_cost}->{$type_id} = int(
				$self->material_base->{$type_id}
				* ( 1 + 0.1 / ( $self->blueprint_mineral_efficiency + 1 ) )
				* ( 1.25 - 0.05 * $self->skill_production_efficiency )
			);
		} else {
			# cost = base * (1 + 0.1 - ME / 10) * (1.25 - 0.05 * ProdEff)
			$self->{material_cost}->{$type_id} = int(
				$self->material_base->{$type_id}
				* ( 1 + 0.1 - $self->blueprint_mineral_efficiency / 10 )
				* ( 1.25 - 0.05 * $self->skill_production_efficiency )
			);
		}
	}

	return $self;
}

sub material_type_ids {
	return keys %{$_[0]->material_base};
}





######################################################################
# Main Methods

sub can_price {
	my $self = shift;
	my $jita = EVE::Market->jita_naive_sell;
	return 0 unless $jita->{ $self->output_type_id };
	foreach my $type_id ( $self->material_type_ids ) {
		return 0 unless $jita->{$type_id};
	}
	return 1;
}

sub output_sell {
	my $self = shift;
	unless ( defined $self->{output_sell} ) {
		my $jita    = EVE::Market->jita_naive_sell;
		my $type_id = $self->output_type_id;
		my $price   = $jita->{$type_id};
		unless ( defined $price ) {
			die "Missing naive jita sell price for '$type_id'";
		}
		$self->{output_sell} = $self->output_quantity * $price;
	}
	return $self->{output_sell};
}

sub material_sell {
	my $self = shift;
	unless ( defined $self->{material_sell} ) {
		my $sell = $self->{material_sell} = {};
		my $jita = EVE::Market->jita_naive_sell;
		foreach my $type_id ( $self->material_type_ids ) {
			my $quantity = $self->material_cost->{$type_id};
			my $price    = $jita->{$type_id};
			unless ( defined $price ) {
				die "Missing naive jita sell price for '$type_id'";
			}
			$sell->{$type_id} = $quantity * $price;
		}
	}
	return $self->{material_sell};
}

1;
