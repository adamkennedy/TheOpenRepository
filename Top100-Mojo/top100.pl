#!/usr/bin/perl

use 5.008;
use strict;
use CPANDB 0.13 {
	maxage => 3600 * 24 * 7,
};
use GraphViz;
use Mojolicious::Lite;

app->types->type( svg => 'image/svg+xml' );





######################################################################
# Index and Form Handling

get '/' => sub {
	my $self = shift;
	$self->render('index');
} => 'index';





######################################################################
# Graph Renderer

get '/graph' => sub {
	my $self = shift;
	render_graph( $self,
		name    => $self->param('name'),
		rankdir => 1,
	);
} => 'graph';

get '/graph/:name' => sub {
	my $self = shift;
	render_graph( $self,
		name    => $self->param('name'),
		rankdir => 1,
	);
};

sub render_graph {
	my $self  = shift;
	my %param = @_;
	my $name  = delete $param{name};
	my $dist  = CPANDB->distribution($name);
	$self->render_data(
		$dist->dependency_graphviz(%param)->as_svg,
		format => 'svg',
	);	
}

shagadelic;
