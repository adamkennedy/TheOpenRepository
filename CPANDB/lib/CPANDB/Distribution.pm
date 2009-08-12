package CPANDB::Distribution;

use 5.008005;
use strict;
use warnings;

our $VERSION = '0.07';





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
	shift->_dependency( _class => 'Graph::XGMML', @_ );
}

sub dependants_xgmml {
	require Graph::XGMML;
	shift->_dependants( _class => 'Graph::XGMML', @_ );
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
			$graph->add_edge( $name => $dep );
		}

		# Push the new ones to the list
		push @todo, grep { not $seen{$_}++ } @deps;
	}

	return $graph;
}

1;
