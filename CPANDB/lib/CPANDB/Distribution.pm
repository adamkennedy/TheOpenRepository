package CPANDB::Distribution;

use 5.008005;
use strict;
use warnings;

our $VERSION = '0.05';





######################################################################
# Graph Integration

use constant NODE_METHOD => {
	'Graph::Directed' => 'add_vertex',
	'Graph::Easy'     => 'add_node',
	'GraphViz'        => 'add_node',
};

use constant EDGE_METHOD => {
	'Graph::Directed' => 'add_edge',
	'Graph::Easy'     => 'add_edge',
	'GraphViz'        => 'add_edge',
};

sub dependency_graph {
	require Graph::Directed;
	shift->_dependency( _class => 'Graph::Directed', @_ );
}

sub dependency_easy {
	require Graph::Easy;
	shift->_dependency( _class => 'Graph::Easy', @_ );
}

sub dependency_graphviz {
	require GraphViz;
	shift->_dependency( _class => 'GraphViz', @_ );
}

sub _dependency {
	my $self     = shift;
	my %param    = @_;
	my $class    = delete $param{_class};
	my $phase    = delete $param{phase};
	my $perl     = delete $param{perl};

	# Prepare support values for the algorithm
	my $add_node  = NODE_METHOD->{$class};
	my $add_edge  = EDGE_METHOD->{$class};
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
			$graph->$add_edge( $name => $dep );
		}

		# Push the new ones to the list
		push @todo, grep { not $seen{$_}++ } @deps;
	}

	return $graph;
}

1;
