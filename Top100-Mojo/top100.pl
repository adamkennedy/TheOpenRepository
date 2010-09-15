#!/usr/bin/perl

use 5.008;
use strict;
use CPANDB 0.13 {
	maxage => 3600 * 24 * 7,
};
use GraphViz;
use Mojolicious::Lite;





######################################################################
# Configuration Block

app->types->type( svg => 'image/svg+xml' );





######################################################################
# Route Handlers

get '/' => sub {
	my $self = shift;
	$self->render('index');
} => 'index';

get '/graph/:name' => sub {
	my $self = shift;
	render_graph( $self,
		name    => $self->param('name') || 'Mojolicious',
		perl    => '5.006001',
		rankdir => 1,
	);
};

post '/graph' => sub {
	my $self = shift;
	render_graph( $self,
		name    => $self->param('name') || 'Mojolicious',
		perl    => $self->param('perl') || '5.006001',
		rankdir => 1,
	);
} => 'graph';

shagadelic;





######################################################################
# Support Functions

sub render_graph {
	my $self  = shift;
	my %param = @_;
	my $dist  = CPANDB->distribution($param{name});
	my $title = '"' . delete($param{name}) . '"';
	my $svg   = $dist->dependency_graphviz( %param, name => $title )->as_svg;
	$self->render_data( $svg, format => 'svg' );
}
