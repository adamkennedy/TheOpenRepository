#!/usr/bin/perl

use 5.008;
use strict;
use CPANDB 0.13 {
	maxage => 3600 * 24 * 7,
};
use GraphViz;
use Mojolicious::Lite;
no warnings;

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
	my $self  = shift;
	my $name  = $self->param('name');
	my $dist  = CPANDB->distribution($name);
	$self->render_data(
		$dist->dependency_graphviz(
			rankdir => 1,
		)->as_svg,
		format => 'svg',
	);
} => 'graph';

get '/graph/:name' => sub {
	my $self  = shift;
	my $name  = $self->stash('name');
	my $dist  = CPANDB->distribution($name);
	$self->render_data(
		$dist->dependency_graphviz(
			rankdir => 1,
		)->as_svg,
		format => 'svg',
	);
};

shagadelic;
