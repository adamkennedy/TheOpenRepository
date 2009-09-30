package CPANDB::Distribution;

use 5.008005;
use strict;
use warnings;
use DateTime ();
use ORLite::Statistics;

our $VERSION = '0.11';

my $today = DateTime->today( time_zone => 'UTC' );





######################################################################
# DateTime Integration

sub uploaded_datetime {
	my $self = shift;
	my @date = split(/-/, $self->uploaded);
	DateTime->new(
		year      => $date[0],
		month     => $date[1],
		day       => $date[2],
		locale    => 'C',
		time_zone => 'UTC',
	);
}

sub age {
	$today - $_[0]->uploaded_datetime;
}

sub age_months {
	$_[0]->age->in_units('months');
}

sub quadrant {
	my $self = shift;

	# Get the boundary dates
	my @quadrant = ref($self)->_quadrant;

	# Find which quadrant we are in
	my $uploaded = $self->uploaded;
	if ( $uploaded gt $quadrant[0] ) {
		return 1;
	} elsif ( $uploaded gt $quadrant[1] ) {
		return 2;
	} elsif ( $uploaded gt $quadrant[2] ) {
		return 3;
	} else {
		return 4;
	}
}

my @QUADRANT = ();

sub _quadrant {
	return @QUADRANT if @QUADRANT;

	# Start with the total number of distributions
	my $class = shift;
	my $rows  = $class->count;
	my $mod   = $rows % 4;
	my $range = ($rows - $mod) / 4;

	# Find the last row in each quadrant
	foreach ( 1 .. 4 ) {
		my $offset = ($range * $_) + $mod - 1;

		# Tweak the boundary rows to deal with row totals
		# that are not divisible by four. By generous about
		# moving edge cases up if so.
		if ( $mod - $_ > 0 ) {
			$offset = $offset - ( $mod - $_ );
		}

		# Find the upload date for the resulting row
		my @object = $class->select("order by uploaded desc limit 1 offset $offset");
		unless ( @object == 1 ) {
			die("Failed to find edge of quadrant $_");
		}

		push @QUADRANT, $object[0]->uploaded;
	}

	return @QUADRANT;
}





######################################################################
# Graph Integration

sub dependency_graph {
	require Graph::Directed;
	shift->_dependency( _class => 'Graph::Directed', @_ );
}

sub dependants_graph {
	require Graph::Directed;
	shift->_dependants( _class => 'Graph::Directed', @_ );
}

sub dependency_easy {
	require Graph::Easy;
	shift->_dependency( _class => 'Graph::Easy', @_ );
}

sub dependants_easy {
	require Graph::Easy;
	shift->_dependants( _class => 'Graph::Easy', @_ );
}

sub dependency_graphviz {
	require GraphViz;
	shift->_dependency( _class => 'GraphViz', @_ );
}

sub dependants_graphviz {
	require GraphViz;
	shift->_dependants( _class => 'GraphViz', @_ );
}

sub dependency_xgmml {
	require Graph::XGMML;
	my $self  = shift;
	my @param = ( @_ == 1 ) ? ( OUTPUT => IO::File->new( shift, 'w' ) ) : ( @_ );
	$self->_dependency( _class => 'Graph::XGMML', @param );
}

sub dependants_xgmml {
	require Graph::XGMML;
	my $self  = shift;
	my @param = ( @_ == 1 ) ? ( OUTPUT => IO::File->new( shift, 'w' ) ) : ( @_ );
	$self->_dependants( _class => 'Graph::XGMML', @param );
}

sub _dependency {
	my $self     = shift;
	my %param    = @_;
	my $class    = delete $param{_class};
	my $phase    = delete $param{phase};
	my $perl     = delete $param{perl};

	# Prepare support values for the algorithm
	my $add_node  = $class->can('add_vertex')
		? 'add_vertex'
		: 'add_node';
	my $sql_where = 'where distribution = ?';
	my @sql_param = ();
	if ( $phase ) {
		$sql_where .= ' and phase = ?';
		push @sql_param, $phase;
	}
	if ( $perl ) {
		$sql_where .= ' and ( core is null or core >= ? )';
		push @sql_param, $perl;
	}

	# Pass any remaining params to the graph constructor
	my $graph = $class->new( %param );

	# Fill the graph via simple list recursion
	my @todo = ( $self->distribution );
	my %seen = ( $self->distribution => 1 );
	while ( @todo ) {
		my $name = shift @todo;
		$graph->$add_node( $name );

		# Find the distinct dependencies for this node
		my %edge = ();
		my @deps = grep {
			not $edge{$_}++
		} map {
			$_->dependency
		} CPANDB::Dependency->select(
			$sql_where, $name, @sql_param,
		);
		foreach my $dep ( @deps ) {
			$graph->add_edge( $name => $dep );
		}

		# Push the new ones to the list
		push @todo, grep { not $seen{$_}++ } @deps;
	}

	return $graph;
}

sub _dependants {
	my $self     = shift;
	my %param    = @_;
	my $class    = delete $param{_class};
	my $phase    = delete $param{phase};
	my $perl     = delete $param{perl};

	# Prepare support values for the algorithm
	my $add_node  = $class->can('add_vertex') ? 'add_vertex' : 'add_node';
	my $sql_where = 'where dependency = ?';
	my @sql_param = ();
	if ( $phase ) {
		$sql_where .= ' and phase = ?';
		push @sql_param, $phase;
	}
	if ( $perl ) {
		$sql_where .= ' and ( core is null or core >= ? )';
		push @sql_param, $perl;
	}

	# Pass any remaining params to the graph constructor
	my $graph = $class->new( %param );

	# Fill the graph via simple list recursion
	my @todo = ( $self->distribution );
	my %seen = ( $self->distribution => 1 );
	while ( @todo ) {
		my $name = shift @todo;
		next if $name =~ /^Task-/;
		next if $name =~ /^Acme-Mom/;
		$graph->$add_node( $name );

		# Find the distinct dependencies for this node
		my %edge = ();
		my @deps = grep {
			not $edge{$_}++
		} map {
			$_->distribution
		} CPANDB::Dependency->select(
			$sql_where, $name, @sql_param,
		);
		foreach my $dep ( @deps ) {
			next if $dep =~ /^Task-/;
			next if $dep =~ /^Acme-Mom/;
			$graph->add_edge( $name => $dep );
		}

		# Push the new ones to the list
		push @todo, grep { not $seen{$_}++ } @deps;
	}

	return $graph;
}

1;
