package CPANDB;

use 5.008005;
use strict;
use warnings;
use IO::File             ();
use Params::Util         ();
use ORLite::Mirror       ();
use CPANDB::Distribution ();

our $VERSION = '0.08';

sub import {
	my $class  = shift;
	my $params = Params::Util::_HASH(shift) || {};

	# Pass through any params from above
	$params->{url}    ||= 'http://svn.ali.as/db/cpandb.bz2';
	$params->{maxage} ||= 24 * 60 * 60; # One day

	# Prevent double-initialisation
	$class->can('orlite') or
	ORLite::Mirror->import( $params );

	return 1;
}

sub distribution {
	my $self = shift;
	my @dist = CPANDB::Distribution->select(
		'where distribution = ?', $_[0],
	);
	unless ( @dist ) {
		die("Distribution '$_[0]' does not exist");
	}
	return $dist[0];
}

sub graph {
	require Graph;
	require Graph::Directed;
	my $class = shift;
	my $graph = Graph::Directed->new;
	foreach my $vertex ( CPANDB::Distribution->select ) {
		$graph->add_vertex( $vertex->distribution );
	}
	foreach my $edge ( CPANDB::Dependency->select ) {
		$graph->add_edge( $edge->distribution => $edge->dependency );
	}
	return $graph;
}

sub easy {
	require Graph::Easy;
	my $class = shift;
	my $graph = Graph::Easy->new;
	foreach my $vertex ( CPANDB::Distribution->select ) {
		$graph->add_vertex( $vertex->distribution );
	}
	foreach my $edge ( CPANDB::Dependency->select ) {
		$graph->add_edge( $edge->distribution => $edge->dependency );
	}
	return $graph;	
}

sub xgmml {
	require Graph::XGMML;
	my $class = shift;
	my $graph = Graph::XGMML->new( directed => 1, @_ );
	foreach my $vertex ( CPANDB::Distribution->select ) {
		$graph->add_vertex( $vertex->distribution );
	}
	foreach my $edge ( CPANDB::Dependency->select ) {
		$graph->add_edge( $edge->distribution => $edge->dependency );
	}
	$graph->end;
	return 1;
}

sub csv {
	my $class = shift;
	my $file  = shift;
	my $csv   = IO::File->new($file, 'w');
	foreach my $edge ( CPANDB::Dependency->select ) {
		$csv->print( $edge->distribution . "\t" . $edge->dependency . "\n" );
	}
	$csv->close;
}

1;
