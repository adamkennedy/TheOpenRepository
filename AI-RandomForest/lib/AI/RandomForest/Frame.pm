package AI::RandomForest::Frame;

use 5.16.0;
use strict;
use warnings;
use Params::Util           1.00 ();
use AI::RandomForest::Selection ();

our $VERSION = '0.01';

use Object::Tiny 1.03 qw{
	table
	row_count
	row_ratio
	sample_count
	sample_ratio
};





######################################################################
# Constructor

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Check params
	unless ( Params::Util::_INSTANCE($self->table, 'AI::RandomForest::Table') ) {
		die "Missing or invalid 'table' param";
	}
	unless ( defined $self->row_count ) {
		if ( defined $self->row_ratio ) {
			$self->{row_count} = $self->table->rows * $self->row_ratio;
		} else {
			$self->{row_count} = $self->table->rows;
		}
	}
	unless ( Params::Util::_NONNEGINT($self->row_count) ) {
		die "Missing or invalid 'row_count' param";
	}
	unless ( $self->row_count <= $self->table->rows ) {
		die "Missing or invalid 'row_count' param";
	}
	unless ( defined $self->sample_count ) {
		if ( defined $self->sample_count ) {
			$self->{sample_count} = $self->table->samples * $self->sample_ratio;
		} else {
			$self->{sample_count} = $self->table->samples;
		}
	}
	unless ( Params::Util::_NONNEGINT($self->sample_count) ) {
		die "Missing or invalid 'sample_count' param";
	}
	unless ( Params::Util::_NONNEGINT($self->sample_count) ) {
		die "Missing or invalid 'sample_count' param";
	}

	return $self;
}





######################################################################
# Main Methods

sub feature_selection {
	my $self    = shift;
	my $feature = shift;
	my $table   = $self->table;
	my $index   = $self->sample_index;

	return AI::RandomForest::Selection->new(
		sort { $a->[0] <=> $b->[0] } map { [ $table->[$_]->{$feature}, $_ ] } @$index
	);
}

sub feature_index {
	my $self = shift;
	unless ( defined $self->{feature_index} ) {
		my @want = ();
		my @have = 0 .. ($self->features - 1);
		foreach ( 1 .. $self->feature_count ) {
			push @want, splice(@have, int(rand($#have)), 1);
		}
		$self->{feature_index} = \@want;
	}
	return $self->{feature_index};
}

sub sample_index {
	my $self = shift;
	unless ( defined $self->{sample_index} ) {
		my @want = ();
		my @have = 0 .. ($self->samples - 1);
		foreach ( 1 .. $self->sample_count ) {
			push @want, splice(@have, int(rand($#have)), 1);
		}
		$self->{sample_index} = \@want;
	}
	return $self->{sample_index};
}

1;
