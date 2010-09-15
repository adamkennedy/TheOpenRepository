#!/usr/bin/perl

use 5.008;
use strict;
use warnings;
use Dancer   1.1805;
use Template 2.22;
use CPANDB   0.14;





######################################################################
# Configuration block

set log      => 'core';
set logger   => 'console';
set template => 'template_toolkit';
set engines  => {
	template_toolkit => {
		start_tag => '[%',
		stop_tag  => '%]',
	},
};





######################################################################
# Route Handlers

get '/' => sub {
	template 'index';
};

post '/graph' => sub {
	return render_graph(
		name    => params->{name} || 'Dancer',
		perl    => params->{perl} || '5.006001',
		rankdir => 1,
	);
};

dance;





######################################################################
# Support Functions

sub render_graph {
	my %param = @_;
	my $dist  = CPANDB->distribution($param{name});
	my $title = '"' . delete($param{name}) . '"';
	my $svg   = $dist->dependency_graphviz( %param, name => $title )->as_svg;
	content_type('image/svg+xml');
	return $svg;
}
